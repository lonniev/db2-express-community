#
# Cookbook Name:: db2-express-community
# Recipe:: default
#
# "Creative Commons BY 2016", Predictable Response Consulting
# "Creative Commons BY 2016", Sodius
#
# See https://en.wikipedia.org/wiki/CC_BY
#

# Ubuntu and Canonical can't decide on Upstart or SystemD
reboot "Restore Upstart" do
  action :nothing
  reason "DB2 assumes Linux still uses Upstart for Services"
  delay_mins 1 # give chef time to return control to Vagrant
end

apt_package 'upstart-sysv' do
  not_if 'dpkg -s upstart-sysv'
  notifies :reboot_now, 'reboot[Restore Upstart]', :immediately
end

# 64-bit DB2 needs some 32-bit crutches
apt_package 'libaio1'
apt_package 'gcc-multilib'

execute 'dpkg --add-architecture i386'
execute 'apt-get update'

apt_package 'libpam0g:i386'

# DB2 scripts use ksh
apt_package 'ksh'

# create users as specified in the bags
include_recipe "manage-users"

# key DB2 users that are needed for the response file and should be in the bags files
db2inst1UserName = node['db2-express-community']['db2inst1UserName']
db2sdfe1UserName = node['db2-express-community']['db2sdfe1UserName']
db2inst1PlainPassword = ""
db2sdfe1PlainPassword = ""

# search up the passwords for the specified users
search( "users", "id:#{db2inst1UserName} AND NOT action:remove") do |usr|

  keys = Chef::EncryptedDataBagItem.load( "private_keys", usr['id'] )

  db2inst1PlainPassword = keys["db2Password"]

end

search( "users", "id:#{db2sdfe1UserName} AND NOT action:remove") do |usr|

  keys = Chef::EncryptedDataBagItem.load( "private_keys", usr['id'] )

  db2sdfe1PlainPassword = keys["db2Password"]

end

# specify which DB2 URL to use
archives = [
  {
    :url => "#{node['db2-express-community']['ibmMarketingSite']}/pick.do?source=swg-db2expressc&S_PKG=dllinux64&S_TACT=000000VR&lang=en_US&S_OFF_CD=10000761",
    :remoteArchive => node['db2-express-community']['remoteArchive'],
    :userEmail => node['db2-express-community']['ibmCustomerEmail'],
    :firstName => node['db2-express-community']['firstName'],
    :lastName => node['db2-express-community']['lastName'],
    :company => node['db2-express-community']['company'],
    :countryCode => node['db2-express-community']['countryCode']
  }
]

# browse the IBM marketing site and collect a credentialed URL for the download
include_recipe 'mechanize'
download_urls = Crawler.download_links( archives )

localTmp = Pathname( node['db2-express-community']['downloadIntoPath'] );
stagingPath = Pathname( node['db2-express-community']['stagingIntoPath'] )
versionedInstallPath = Pathname( node['db2-express-community']['versionedInstallPath'] )
localExtract = localTmp.join( node['db2-express-community']['localArchive'] )
stagingFileCheck = stagingPath.join( 'expc/db2_install' )

remoteUrl = ( download_urls.first.uri().to_s unless download_urls.empty? ) || node['db2-express-community']['fallback']

[ localTmp.to_s, stagingPath.to_s ].each{ |dir|
  directory dir do
    action :create
    recursive true
  end
}

# retrieve the db2-express-community archive from the IBM site
remote_file localExtract.to_s do

  source remoteUrl

  checksum node['db2-express-community']['sha256']

  action :create_if_missing

  not_if { remoteUrl.empty? }

  only_if { !localExtract.exist? }

end

# extract the tar into the staging area
tarball localExtract.to_s do

  destination stagingPath.to_s

  action :extract

  only_if { !remoteUrl.empty? }
  not_if { stagingFileCheck.exist? }

end

responseFile = stagingPath.join( node['db2-express-community']['db2ResponseFile'] )

# construct a DB2 setup Response File
template responseFile.to_s do

  source 'db2ResponseFile.erb'

  variables(
    versionedInstallPath: "#{versionedInstallPath}",
    installType: "#{node['db2-express-community']['installType']}",
    db2inst1UserName: "#{db2inst1UserName}",
    db2inst1PlainPassword: "#{db2inst1PlainPassword}",
    db2sdfe1UserName: "#{db2sdfe1UserName}",
    db2sdfe1PlainPassword: "#{db2sdfe1PlainPassword}"
  )

  owner 'root'
  group 'root'
  mode '0644'

  not_if { db2inst1PlainPassword.empty? || db2sdfe1PlainPassword.empty? }

end

# Install DB2 using the generated Response File
execute 'install db2' do

  command "#{stagingPath.join( 'expc' )}/db2setup -r #{responseFile}"
  cwd stagingPath.to_s
  action :run

  only_if { responseFile.exist? }
  not_if 'service db2fmcd status' # true when db2fmcd is installed and running

end

# Autostart both the DB2 Fault Manager and the Installed instance
execute "#{versionedInstallPath.join( 'bin' )}/db2iauto -on #{db2inst1UserName}"
