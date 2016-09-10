# JobSearch
Automate dice.com job searches using windows powershell script, the dice API, JSON configuration file, and scheduled tasks.

### Command line example:
powershell -file "C:\location\powershell\script\JobSearch.ps1" "C:\location\json\config\weekly-example.json" "email-password"

### Configuration Example:
```json
{
	"uri": "http://service.dice.com/api/rest/jobsearch/v2/simple.xml?",
	"mail-config": {
		"from": "example@gmail.com",
		"to": "example@gmail.com",
		"smtp": "smtp.gmail.com",
		"port": "587",
		"username": "example@gmail.com"
	},
	"searches": 
	[
			{
			"title": "Weekly - Support - Remote",
			"keyword": "support",
			"age": "7",
			"sort": "3",
			"telecommute": "true"
		},
		{
			"title": "Weekly - Support - 85258",
			"country": "USA",
			"age": "7",
			"sort": "1",			
			"keyword": "support",
			"city": "85258",
			"include": [
				"desk",
				"tech",
				"analyst"
			],
			"exclude": [
				"senior",
				"sr",
				"manager",
				"lead",
				"engineer",
				"director",
				"programmer"
			]
		},
		{
			"title": "Weekly - Support - Portland",		
			"country": "USA",
			"state": "OR",
			"city": "Portland",
			"age": "7",
			"sort": "1",			
			"keyword": "support",
			"parttime": "true"
		}
	]
}
```
### Example Explained:
#### URI
- This is dice.com 's API end point
- API is currently at version 2

#### Mail Configuration
- Basic settings required by Powershells "Send-MailMessage" cmdlet
- Example uses gmail. *Gmail may require you to authorize app*

#### Searches
- You must have at least one search in the configuration file
- The only *required* value in a search is the *keyword* value
- Default values cosist of: (country=USA, age=21, sort=1, title=Automated Dice JobSearch)

#### Search Parameters
- keyword - Mandatory field used to search entire job posting for specified word
- title - Used in the subject line of the email
- country - ISO 3166 Country Code [List] (https://www.iso.org/obp/ui/#search)
- state - US Postal State Code [List] (http://www.bls.gov/cew/cewedr10.htm)
- city - ZIP Code *or* City Name
- skill - Searches the skill section for specified word
- direct - Direct Hire (true or false)
- telecommute - Position is listed as telecommute (true or false)
- fulltime - This is a full time position (true or false)
- parttime - This is a part time position (true or false)
- contract - This is a contract position (true or false)



#### The URI is dice.com 's base API endpoint. It is currently on version 2, and this could potentially be replaced if/when a newer version becomes available.



```json
"uri": "http://service.dice.com/api/rest/jobsearch/v2/simple.xml?",
```




### Dice.com API reference:
http://www.dice.com/common/content/util/apidoc/jobsearch.html
