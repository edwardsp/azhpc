#!/bin/sh

for model in sedan_4m.tar aircraft_wing_14.tar f1_racecar_140m.tar; do
	wget http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/${model} -O - | tar x
done

