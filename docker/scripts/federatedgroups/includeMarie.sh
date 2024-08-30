#!/usr/bin/env bash

set -e

curl --request PUT \
  --url "https://$1/index.php/apps/federatedgroups/scim/Groups/TestGroup%20(uniharderwijk_surfdrive_test)%20(SRAM%20CO)" \
  --header 'Content-Type: application/json' \
  --header 'x-auth: Bearer something-super-secret' \
  --cookie 'ocvzvyc9ti1g=3ke8v4tvguika5b618elqodovu; ocp9eud6ezkt=u2b56ls1bpt8d57vcloe1c6q0m; oci50bcnk8nq=gjjhcavr17mcff3vadvjdn47uk; ocxougkoe4sh=hu5ve2k0i03jvoobct7h7gapfk; oc9f2lksuaal=1pofgkelnpj2o72r3nq3cnoqte' \
  --data '{
   "displayName":"TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)",
   "externalId":"3f938b6b-cbe0-4856-beb3-91dffa773c15@sram.surf.nl",
   "members":[
      {
         "display":"owncloud1 user with email",
         "value":"some-super-long-email-user-name@some-super-long-email-domain-where-this-user-has-their-email-hosting.nl@owncloud1.docker"
      },
      {
         "display":"owncloud2 user with email",
         "value":"some-super-long-email-user-name@some-super-long-email-domain-where-this-user-has-their-email-hosting.nl@owncloud2.docker"
      },
      {
         "display":"einstein@owncloud1.docker",
         "value":"einstein@owncloud1.docker"
      },
      {
         "display":"marie@owncloud2.docker",
         "value":"marie@owncloud2.docker"
      }
   ],
   "urn:mace:surf.nl:sram:scim:extension:Group":{
      "description":"Provisioned by service Research Drive test - ",
      "labels":[

      ],
      "urn":"uniharderwijk:surfdrive_test:srd_test-testgroup"
   },
   "schemas":[
      "urn:ietf:params:scim:schemas:core:2.0:Group",
      "urn:mace:surf.nl:sram:scim:extension:Group"
   ],
   "id":"TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)",
   "meta":{
      "created":"2023-05-09T09:28:12.589456",
      "lastModified":"2023-05-09T09:28:12.602001",
      "location":"/Groups/848a0f5d-b492-4580-80f1-1950cf7be410",
      "resourceType":"Group"
   }
}'
