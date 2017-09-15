import jsonRepo as jsonRepo
import config as config

class pynina():
    """ main driver"""
    def __init__(self):
        self.jsonRepo = jsonRepo(config.DOCUMENTDB_ENDPOINT, config.DOCUMENTDB_AUTHKEY, config.DOCUMENTDB_DATABASE, config.DOCUMENTDB_COLLECTION)

    def saveFromFile(self, jsonFile):
        # load json document
        with open(jsonFile, 'r') as f:
            self.jsonRepo.UpdateDocument(f.read())

