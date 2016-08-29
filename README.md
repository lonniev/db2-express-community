# db2-express-community Cookbook

Prepares a Ubuntu Linux VM to support 64-bit DB2 and its Instance and Fenced Users.

Visits the IBM Marketing Site to complete the Contact registration process in order to
obtain a credentialed URL for the DB2 Express Community Edition installer.

It then downloads and extracts that installer.

It then prepares a DB2 silent install Response File.

It installs DB2 Express Community Edition according to the Response File and starts it.

## Requirements

### Databags

- The recipe relies on public `users/userid.json` files for each of the DB2 instance users. The passwords for these users are stored in private_data_bag `userid.json` files that each have a public `id` property and an encrypted `db2Password` property.

### Platforms

- Ubuntu 64-bit (amd64)

### Chef

- Chef 12.10

### Cookbooks

- `mechanize` - db2-express-community needs mechanize to crawl the IBM site.
- `tarball` - db2-express-community uses tarball to unpack tgz files
- `manage-users` - db2-express-community needs manage-users to create the Unix user accounts for the DB2 users and to provide the plaintext passwords to the DB2 Response File for these users.

## Attributes

### db2-express-community::default

```json
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
```

## Usage

### db2-express-community::default

Just include `db2-express-community` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[db2-express-community]"
  ]
}
```

# License and Authors

Authors: Lonnie VanZandt
