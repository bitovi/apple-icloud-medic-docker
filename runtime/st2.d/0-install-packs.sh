#/bin/bash

## install the pack
st2 pack install email st2 splunk

st2ctl reload --register-configs