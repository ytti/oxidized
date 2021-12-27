# Model Notes
UFiber OLTs works with a .tar.gz file for backups, as it comprises not just the running-config, but some additional config files.
The output is obtained in base64 enconding.

To convert this into a .tar.gz file, please do
```
base64 -d <data_in_oxidized>  > myolt.tar.gz
```