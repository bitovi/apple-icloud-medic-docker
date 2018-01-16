#/bin/bash
MEDIC_EXCHANGE_DIRECTORIES=/opt/stackstorm/medic-exchange/*

# remove all packs, first
for d in $MEDIC_EXCHANGE_DIRECTORIES
do
  echo "removing existing medic-exchange pack: $(basename $d)"
  st2 pack remove $(basename $d)
done

# then install all packs
for d in $MEDIC_EXCHANGE_DIRECTORIES
do
  echo "installing medic-exchange pack: $d..."
  st2 pack install file:///$d
done