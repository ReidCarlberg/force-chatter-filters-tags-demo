public with sharing class ChatterCloudUtility {

	ChatterCloudSettings__c settings = ChatterCloudSettings__c.getInstance();
	
	static final Integer FILTER_MINIMUM_LENGTH = 4;
	static final Integer FILTER_MINIMUM_SCORE = 5;
	
	static final Set<String> FILTER_INCLUDED = new Set<String> { 'sale' };
	static final Set<String> FILTER_EXCLUDED = new Set<String> { 'shit' };


	public Set<String> buildSignificant() {
		
		/*
		If the user doesn't initialize settings, do it here.
		*/
		if (settings == null) {
			settings = new ChatterCloudSettings__c(SetupOwnerId = UserInfo.getOrganizationId());
			settings.Include_At_Tags__c = true;
			settings.Include_Hash_Tags__c = true;
			settings.Include_Custom_Tag__c = false;
			settings.Minimum_Word_Score__c = 4;
			Database.upsert(settings);
		}
		Set<String> ret = new Set<String>();
		
		List<UserFeed> userFeeds = [SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, 
			FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title From UserFeed Order By CreatedDate DESC LIMIT 100];
			
		for (UserFeed current : userFeeds) {
			ret.addAll(this.buildSignificant(current.FeedPost.Body));
		}
		
		return ret;
	}
	

	
	public List<String> buildSignificant(String target) {

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
			if (getWordScore(current) >= minWordScoreLocal) {
				if (current.endsWith('.') || current.endsWith(',') || current.endsWith('-')) {
					current = current.substring(0,current.length()-1);
				}
				ret.add(current.toLowerCase());
			}
		}
		
		return ret;

		
	}
	
	public Decimal getWordScore(String word) {
		Decimal ret = 0;

		if (settings != null) {
			if (settings.Include_Hash_Tags__c && word.startsWith('#')) {
				ret += settings.Minimum_Word_Score__c;
			}
			if (settings.Include_At_Tags__c && word.startsWith('@')) {
				ret += settings.Minimum_Word_Score__c;
			}		
			if (settings.Include_Custom_Tag__c && word.startsWith(settings.Custom_Tag_Prefix__c)) {
				ret += settings.Minimum_Word_Score__c;
			}
		}
		
		/*
		if (settings.Include_Significant_Words__c) {
			if(FILTER_EXCLUDED.contains(word)) { 
				// auto exclusion
				ret = 0;
			} else if (Integer.valueOf(word) > 0) {
				// it's a number, not interesting
				ret = 0;
			} else {
				// the hard part
				//length
				if(word.length() >= settings.Minimum_Word_Length__c) { ret+=3; }
				//action
				if(word.endsWith('ing')) { ret += 3; }
			}
		}
		*/
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
		
		Decimal t1 = new ChatterCloudUtility().getWordScore('#nice');
		
		System.assert(t1 >= settings.Minimum_Word_Score__c);
		
		Decimal t2 = new ChatterCloudUtility().getWordScore('@nice');
		
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
		
		List<String> r = new ChatterCloudUtility().buildSignificant(t1);
		
		System.debug('size is ' + r.size());
		
		System.debug('word one is ' + r.get(0));
		
		System.assert(r.size() == 2);
		
	}
	
	static TestMethod void testFromFeed() {
		
		User testUser = TestUtility.createTestUser();
		String word1 = TestUtility.createRandomWord();
		String word2 = TestUtility.createRandomWord();
		TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words #' + word1 + ' and @' + word2 + ' in it');
		TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it');	
		
		ChatterCloudUtility utility = new ChatterCloudUtility();
		
		Set<String> words = utility.buildSignificant();
		
		System.assert(words.contains('#'+word1));
		System.assert(words.contains('@'+word2));
		
	}
	
}