import config as config
from jsonrepo import jsonrepo

class pynina():

    def __init__(self):
        self.jsonRepo = jsonrepo(config.DOCUMENTDB_ENDPOINT, config.DOCUMENTDB_AUTHKEY, config.DOCUMENTDB_DATABASE, config.DOCUMENTDB_COLLECTION)

    def saveFromFile(self, jsonFile):
        # load json document
        with open(jsonFile, 'r') as F:
            self.jsonRepo.UpdateDocument(F.read())

