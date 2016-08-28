#
# Cookbook Name:: db2-express-community
# Recipe:: default
#
# Copyright 2016, Predictable Response Consulting
#
# All rights reserved - Do Not Redistribute
#

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

remoteUrl = ( download_urls.first.uri().to_s unless download_urls.empty? ) || ""

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
    db2Password: "#{node['db2-express-community']['db2Password']}"
  )

  owner 'root'
  group 'root'
  mode '0644'

end

# Install DB2 using the generated Response File
execute 'install db2' do
  command "#{stagingPath.join( 'expc' )}/db2setup -r #{responseFile}"
  cwd stagingPath.to_s
  action :run
end
