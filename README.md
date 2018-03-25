# PPA resource for Concourse CI

With this resource you can check and fetch source packages from a ppa, it also
doubles as a package duplicator for automated backports of new packages to all
supported Ubuntu versions. For uploading packages,
[dput](https://github.com/seveas/concourse-dput-resource) resource can be used.

To use this resource, you will need to generate a launchpad API token. The
easiest way to do so is to use the bundled script:

```
bin/generate-launchpad-token lp-token.txt
```

This script outputs a link to launchpad. Open the link and select 'until I
disable it'. Credentials will now be saved in the file `lp-token.txt. You can
then store it in your credential store, e.g. vault:

```
vault write concourse/main/launchpad-token value=@lp-token.txt
```

## Source configuration

To use this resource, you can configure it as below. The example job uses the
`ppa-split` tool to automatically copy any new PPA upload to all supported
Ubuntu releases.

```
resource_types:
  - name: ppa
    type: docker-image
    source:
      repository: seveas/concourse-ppa-resource

resources:
  - name: yourpackage-ppa
    type: ppa
    source:
      ppa: yourlogin/yourppa
      package: yourpackage
      api_token: ((launchpad-token))

jobs:
  - name: ppa-porter
    plan:
      - get: yourpackage-ppa
        trigger: true
      - task: split
        config:
          platform: linux
          image_resource:
            type: docker-image
            source:
              repository: seveas/concourse-ppa-resource
              tag: latest
          inputs:
            - name: yourpackage-ppa
          outputs:
            - name: sources
          run:
            path: sh
            args: 
              - -exc
              - |
                perl -E 'say $ENV{GPG_KEY}' | gpg --import
                ppa-split yourpackage-ppa ../sources
          params:
            GPG_KEY: ((gpg-key))
            API_TOKEN: ((launchpad-token))
            DEBFULLNAME: Your Name
            DEBEMAIL: your@email
      - put: yourpackage-dput
        params:
          archive: ppa:yourlogin/yourppa
          glob: sources/*.changes

