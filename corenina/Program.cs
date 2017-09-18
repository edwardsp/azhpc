using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Net;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Microsoft.Extensions.Configuration;

namespace corenina
{
    class Program
    {
        // private const string _endpointUri = "https://ninadb.documents.azure.com:443/";
        // private const string _primaryKey = "tH0qjX7LoEDNlGH8gER9j7wqXejslxoqwxTguV1iQi7vWsiQV5hooafnQvnIJRsXWrJEixrZ2RBiEP59kBt1Xg==";
        private const string _dbName = "Nina";
        private const string _collectionId = "Results";
        private DocumentClient _client;
        private static IConfigurationRoot _config;

        static void Main(string[] args)
        {
            try
            {
                if (args.Length < 1)
                {
                    Console.WriteLine("Missing json file path");
                    return;
                }
                // Get the configuration
                _config = BuildConfiguration();
                
                Program p = new Program();
                p.UploadJsonFile(args[0]).Wait();
            }
            catch (DocumentClientException de)
            {
                Exception baseException = de.GetBaseException();
                Console.WriteLine("{0} error occurred: {1}, Message: {2}", de.StatusCode, de.Message, baseException.Message);
            }
            catch (Exception e)
            {
                Exception baseException = e.GetBaseException();
                Console.WriteLine("Error: {0}, Message: {1}", e.Message, baseException.Message);
            }
        }

        private async Task UploadJsonFile(string fileName)
        {
            using (StreamReader sr = File.OpenText(fileName))
            {
                string json = sr.ReadToEnd();
                JObject o = JObject.Parse(json);
                this._client = new DocumentClient(new Uri(_config["EndpointUri"]), _config["PrimaryKey"]);

                ResourceResponse<Document> response = await this._client.UpsertDocumentAsync(UriFactory.CreateDocumentCollectionUri(_dbName, _collectionId), o);
                var createdDocument = response.Resource;
                Console.WriteLine("Document with id {0} created", createdDocument.Id);
            }
        }

        /// <summary>
        /// Build the confguration
        /// </summary>
        /// <returns>Returns the configuration</returns>
        private static IConfigurationRoot BuildConfiguration()
        {
            // Enable to app to read json setting files
            var builder = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false);

            return builder.Build();
        }        
    }
}
