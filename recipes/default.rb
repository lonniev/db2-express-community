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
    :userEmail => node['db2-express-community']['jazz_user'],
    :firstName => node['db2-express-community']['firstName'],
    :lastName => node['db2-express-community']['lastName'],
    :company => node['db2-express-community']['company'],
    :countryCode => node['db2-express-community']['countryCode']
  }
]

# obtain the source URLs for the three zips
include_recipe 'mechanize'

download_urls = Crawler.download_links( archives )

# download the DB2 remote archive
localTmp = Pathname( node['db2-express-community']['download_into_path'] );
installPath = Pathname( node['db2-express-community']['install_into_path'] )
localExtract = localTmp.join( node['db2-express-community']['local_archive'] )
installedFile = installPath.join( 'foo' )

remoteUrl = ( download_urls.first.uri().to_s unless download_urls.empty? ) || ""

[ localTmp.to_s, installPath.to_s ].each{ |dir|
  directory dir do
    action :create
  end
}

remote_file localExtract.to_s do

  action :create_if_missing

  source remoteUrl
  path localTmp.to_s

  checksum node['db2-express-community']['sha256']

  not_if { remoteUrl.empty? }
end

bash 'extract_module' do

  code <<-EOH
    tar xzf #{localExtract} -C #{installPath}
    EOH
  not_if { installedFile.exist? }
end
