#
# pip install pydocumentdb
#
from pynina import pynina
import config as config

print(config.DOCUMENTDB_AUTHKEY)

APP = pynina()
APP.saveFromFile("telemetry.json")
