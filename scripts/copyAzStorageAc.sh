#!/bin/sh

DST_STORAGE_KEY=t4jhijpb/0AGNzS6y8iykwJzaL43MhFm2gGZiM0/DSG0jLkh7irGEwWHqeOUFlGH9mxHfdlHNjbsRHPSzGdrQw==
SAS_TOKEN="sv=2016-05-31&si=read&sr=b&sig=5ZluFkKL%2F3GyNexDVQBB1sEmUdHpkutLlXaLfE%2BmUN4%3D"

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob stream.96GB \
    --destination-container application \
    --source-uri https://paedwar.blob.core.windows.net/public/stream.96GB

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob hpl.tgz \
    --destination-container application \
    --sas-token  $SAS_TOKEN \
    --source-uri 'https://pintaprod.blob.core.windows.net/private/hpl.tgz?sv=2016-05-31&si=read&sr=b&sig=5ZluFkKL%2F3GyNexDVQBB1sEmUdHpkutLlXaLfE%2BmUN4%3D'

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob LeMans_100M.tgz \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/LeMans_100M.tgz


az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob motorbike82M_64x16.tar \
    --destination-container application \
    --source-uri https://paedwar.blob.core.windows.net/public/motorbike82M_64x16.tar

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob  ANSYS.tgz \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/ANSYS.tgz


az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob  OpenFOAM-4.x_gcc48.tgz \
    --destination-container application \
    --source-uri https://paedwar.blob.core.windows.net/public/OpenFOAM-4.x_gcc48.tgz 

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob  STAR-CCM+12.02.010_01_linux-x86_64.tar.gz \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+12.02.010_01_linux-x86_64.tar.gz
 
az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob  STAR-CCM+11.04.012_01_linux-x86_64-r8.tar.gz \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+11.04.012_01_linux-x86_64-r8.tar.gz 

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob  sedan_4m.tar \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/sedan_4m.tar

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob f1_racecar_140m.tar \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/f1_racecar_140m.tar

az storage blob copy start \
    --account-name ninalogs \
    --account-key $DST_STORAGE_KEY \
    --destination-blob aircraft_wing_14.tar \
    --destination-container application \
    --source-uri http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/aircraft_wing_14.tar









