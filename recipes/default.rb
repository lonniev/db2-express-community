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
    :url => "#{node['db2-express-community']['ibm_marketing_site']}/pick.do?source=swg-db2expressc&S_PKG=dllinux64&S_TACT=000000VR&lang=en_US&S_OFF_CD=10000761",
    :remote_archive => node['db2-express-community']['remote_archive'],
    :userEmail=> node['db2-express-community']['jazz_user'],
    :firstName=> node['db2-express-community']['firstName'],
    :lastName=> node['db2-express-community']['lastName'],
    :company=> node['db2-express-community']['company'],
    :countryCode=> node['db2-express-community']['countryCode'],
  }
]

# obtain the source URLs for the three zips
include_recipe 'mechanize'

download_urls = Crawler.download_links( archives )

# download the DB2 remote archive
localTmp = Pathname( '/tmp' );
installPath = Pathname( node['db2-express-community']['extract_path'] )
localExtract = installPath.join( node['db2-express-community']['local_archive'] )

remote_file node['db2-express-community']['local_archive'] do

  action :create_if_missing

  source download_urls[0].uri().to_s
  path localTmp.to_s

  checksum node['db2-express-community']['sha256']

  owner "vagrant"
  group "vagrant"

  only_if { download_urls[0].respond_to?( :uri ) }
end

bash 'extract_module' do

  cwd localTmp.to_s

  code <<-EOH
    mkdir -p #{installPath}
    tar xzf #{localTmp.join( node['db2-express-community']['local_archive'] )} -C #{installPath}
    EOH
  not_if { localExtract.exists? }
end
