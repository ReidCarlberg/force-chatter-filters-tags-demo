public with sharing class ChatterCloudUtility {

	ChatterCloudSettings__c settings = ChatterCloudSettings__c.getInstance();
	
	private void validateSettings() {
		/*
		If the user doesn't initialize settings, do it here.
		*/
		if (settings == null) {
			settings = new ChatterCloudSettings__c(SetupOwnerId = UserInfo.getOrganizationId());
			settings.Include_At_Tags__c = true;
			settings.Include_Hash_Tags__c = true;
			settings.Include_Custom_Tag__c = true;
			settings.Custom_Tag_Prefix__c = '^';
			settings.Minimum_Word_Score__c = 4;
			Database.upsert(settings);
		}		
	}

	private Set<String> handleBuildSet(List<UserFeed> userFeeds, String setType) {
		Set<String> ret = new Set<String>();
					
		for (UserFeed current : userFeeds) {
			ret.addAll(this.buildSignificant(current.FeedPost.Body, setType));
		}
		
		return ret;
	}
	
	public Set<String> buildKeywords(String keywordType) {
		if (keywordType != null && keywordType != '' && keywordType != 'tag' && keywordType != 'address') {
			keywordType = 'tag';
		}
		
		if (keywordType != null) {
			keywordType = keywordType.tolowerCase();
		}
		
		Set<String> simpleKeywords = null;
		
		if (keywordType == 'tag') {
			simpleKeywords = buildSignificantHash();
		} else if (keywordType == 'address') {
			simpleKeywords = buildSignificantAddress();
		} else {
			simpleKeywords = new ChatterKeywordQuery().getMyKeywordStrings(); 
		}

		return simpleKeywords;
		
	}

	public Set<String> buildSignificant() {
		
		validateSettings();
		
        List<UserFeed> userFeeds = [SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, 
            FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title From UserFeed Where FeedPost.Body Like '%#%' or FeedPost.Body Like '%@%' Order By CreatedDate DESC LIMIT 200];

		return handleBuildSet(userFeeds, 'all');
	}

	public Set<String> buildSignificantHash() {
		
		validateSettings();
		
        List<UserFeed> userFeeds = [SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, 
            FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title From UserFeed Where FeedPost.Body Like '%#%' Order By CreatedDate DESC LIMIT 200];

		return handleBuildSet(userFeeds, 'hash');
	}
	
	public Set<String> buildSignificantAddress() {
		
		validateSettings();
		
        List<UserFeed> userFeeds = [SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, 
            FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title From UserFeed Where FeedPost.Body Like '%@%' Order By CreatedDate DESC LIMIT 200];

		return handleBuildSet(userFeeds, 'address');
	}

	
	public List<String> buildSignificant(String target, String setType) {

		List<String> ret = new List<String>();
		
		Decimal minWordScoreLocal = 0;
		
		if (settings != null) {
			minWordScoreLocal = settings.Minimum_Word_Score__c;
		}
		
		if (target == null) {
			return ret;
		}
		
		//target = target.replaceAll('[\\\\\\.,-_]', '');
		
		String[] words = target.split(' ');
		
		for (String current : words) {
			if (getWordScore(current, setType) >= minWordScoreLocal) {
				if (current.endsWith('.') || current.endsWith(',') || current.endsWith('-')) {
					current = current.substring(0,current.length()-1);
				}
				ret.add(current.toLowerCase());
			}
		}
		
		return ret;

		
	}
	
	public Decimal getWordScore(String word, String setType) {
		Decimal ret = 0;

		if (settings != null) {
			//too short, abort
			if (word.length() < settings.Minimum_Word_Length__c) {
				return ret;
			}
			if ((setType == 'all' || setType == 'hash') && settings.Include_Hash_Tags__c && word.startsWith('#')) {
				ret += settings.Minimum_Word_Score__c;
			}
			if ((setType == 'all' || setType == 'address') && settings.Include_At_Tags__c && word.startsWith('@')) {
				ret += settings.Minimum_Word_Score__c;
			}		
			if (settings.Include_Custom_Tag__c && word.startsWith(settings.Custom_Tag_Prefix__c)) {
				ret += settings.Minimum_Word_Score__c;
			}
		}
		

		return  ret;
	}
	
	static TestMethod void testDefaultSettings() {
	
		ChatterCloudUtility utility = new ChatterCloudUtility();
		
		utility.settings = null;
		
		utility.buildSignificant();
		
		System.assert(utility.settings != null);
		
	}
	
	static TestMethod void testWordScore() {
		
		ChatterCloudSettings__c settings = ChatterCloudSettings__c.getInstance();
		
		if (settings == null) {
			settings = new ChatterCloudSettings__c(SetupOwnerId = UserInfo.getOrganizationId());
			settings.Minimum_Word_Score__c = 5;
			settings.Include_Hash_Tags__c = true;
			settings.Include_At_Tags__c = true;
			settings.Include_Custom_Tag__c = false;
			Database.upsert(settings);
		}
		
		Decimal t1 = new ChatterCloudUtility().getWordScore('#nice', 'all');
		
		System.assert(t1 >= settings.Minimum_Word_Score__c);
		
		Decimal t2 = new ChatterCloudUtility().getWordScore('@nice', 'all');
		
		System.assert(t2 >= settings.Minimum_Word_Score__c);
		

	}
	
	static TestMethod void testGroupOfWords() {
		
		ChatterCloudSettings__c settings = ChatterCloudSettings__c.getInstance();
		
		if (settings == null) {
			settings = new ChatterCloudSettings__c();
			settings.Minimum_Word_Score__c = 5;
			settings.Include_Hash_Tags__c = true;
			settings.Include_At_Tags__c = true;
			settings.Include_Custom_Tag__c = false;
			Database.upsert(settings);
		}
		
		String t1 = 'this is a @group of #words';
		
		List<String> r = new ChatterCloudUtility().buildSignificant(t1, 'all');
		
		System.debug('size is ' + r.size());
		
		System.debug('word one is ' + r.get(0));
		
		System.assert(r.size() == 2);
		
	}
	
	static TestMethod void testFromFeed() {
		
		User testUser = TestUtility.createTestUser();
		String word1 = TestUtility.createRandomWord();
		String word2 = TestUtility.createRandomWord();
		String word3 = TestUtility.createRandomWord();
		TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words #' + word1 + ' and @' + word2 + ' in it');
		TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it');
		TestUtility.addSingleKeyword(word3);	 
		
		ChatterCloudUtility utility = new ChatterCloudUtility();
		
		Set<String> words = utility.buildSignificant();
		
		System.assert(words.contains('#'+word1));
		System.assert(words.contains('@'+word2));
		System.assert(!words.contains(word3));
		
		words = utility.buildSignificantHash();
		
		System.assert(words.contains('#'+word1));
		System.assert(!words.contains('@'+word2));
		System.assert(!words.contains(word3));

		words = utility.buildSignificantAddress();
		
		System.assert(!words.contains('#'+word1));
		System.assert(words.contains('@'+word2));	
		System.assert(!words.contains(word3));
		
		words = utility.buildKeywords('tag');
		
		System.assert(words.contains('#'+word1));
		System.assert(!words.contains('@'+word2));	

		words = utility.buildKeywords('garbage');
		System.assert(words.contains('#'+word1));
		System.assert(!words.contains('@'+word2));	

		words = utility.buildKeywords('address');
		System.assert(!words.contains('#'+word1));
		System.assert(words.contains('@'+word2));
		
		words = utility.buildKeywords(null);
		System.assert(!words.contains('#'+word1));
		System.assert(!words.contains('@'+word2));
		System.assert(words.contains(word3));	
			

	}
	
}