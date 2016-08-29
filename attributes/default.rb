default['db2-express-community'] =
{
  'remoteArchive' => "v11.1_linuxx64_expc.tar.gz",
  'ibmMarketingSite' => "https://www-01.ibm.com/marketing/iwm/iwm/web",
  'ibmCustomerEmail' => "customer@company.com",
  'firstName' => "First",
  'lastName' => "Last",
  'company' => "Acme",
  'countryCode' => "US",
  'localArchive' => 'DB2ExpressC11_linux_x64.tgz',
  'sha256' => 'f8592a47f2dfc2207f4ac3b7fd519cb3a15a4db5b4aaf1f69817d309f6c6ce1f',

  'downloadIntoPath' => '/tmp',
  'stagingIntoPath' => '/tmp/IBM/db2Stage',
  'versionedInstallPath' => '/opt/IBM/db2/version',
  'installType' => 'TYPICAL',
  'db2ResponseFile' => 'db2ResponseFileForYou',

  'db2inst1UserName' => 'db2inst1',
  'db2sdfe1UserName' => 'db2sdfe1'
}
