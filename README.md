# puppet-prefpane

Installs prefpanes for OS X users, from zip files or disk images.

## Usage

```puppet
prefpane { 'teleport':
  source => 'http://www.abyssoft.com/software/teleport/downloads/teleport.zip'
}

prefpane { 'MenuMeters':
  source => 'http://www.ragingmenace.com/software/download/MenuMeters.dmg',
}
```
