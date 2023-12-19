## Solid remote storage development
 In order to start development:
```sh
./init/solid-remote-storage.sh
 ```
This will create a folder named `remotestorage-dev`. There will be cloned directories for repositories [remotestorage.js](https://github.com/pondersource/remotestorage.js) and [remotestorage-widget](https://github.com/pondersource/remotestorage-widget/) in folders respectively called `remotestorage` and `remotestorage-widget`.

After init you have to run the server by using this command:
```sh
./dev/solid-remote-storage.sh
```
And a server will be listening to port `8080`.

After making a change to each of the remotstorage.js or remotestorage-widget repositories, make sure to call:
```sh
./scripts/solid-rebuild-remote-storage.sh
```
This will rebuild both of the repositories and copy the js files into the `remotestorage-dev` folder.


In order to remove directories created by init script, run this script:

WARNING: COMMIT AND PUSH YOUR CHANGES BEFORE RUNNING THIS

```sh
./scripts/solid-remove-remote-storage.sh
```
