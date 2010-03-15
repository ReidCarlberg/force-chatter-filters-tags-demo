/*
	reid.carlberg@salesforce.com
	uses Keywords to find Chatter UserFeed entries.
*/
public with sharing class ChatterKeywordQuery {

	/*
	returns a list of the running users stored keywords
	*/
    public List<Chatter_Keywords__c> getMyKeywords() {
        
            Id currentUser = UserInfo.getUserId();
            
            List<Chatter_Keywords__c> myKeywords = [SELECT Id, Name FROM
            Chatter_Keywords__c WHERE OwnerId =: currentUser];
            
            return myKeywords;
    }
    
    public List<String> getMyKeywordStrings() {

		return this.getSimpleKeywords(this.getMyKeywords());
		        
    }
    
    /*
    converts a list of keyword to a list of strings
    */
    public List<String> getSimpleKeywords(List<Chatter_Keywords__c> keywords) {
    
    	List<String> simpleKeywords = new List<String>();
    	
    	for (Chatter_Keywords__c currentKeyword : keywords) {
    		simpleKeywords.add(currentKeyword.Name);
    	}
    	
    	return simpleKeywords;
    		
    }
    
    /*
    returns a list of user feeds based on the keywords a user has stored
    */
    public List<UserFeed> getPosts() {
    	List<Chatter_Keywords__c> myKeywords = this.getMyKeywords();
    	List<String> simpleKeywords = this.getSimpleKeywords(myKeywords);
    	return this.getPosts(simpleKeywords);
    }
    
    /*
    returns a list of users feeds matching a single keyword -- this keyword does not have to be stored
    */
    public List<UserFeed> getPosts(String singleKeyword) {
    	List<String> simpleKeywords = new List<String>();
    	simpleKeywords.add(singleKeyword);
    	return this.getPosts(simpleKeywords);
    }
    
    /*
    returns a list of user feed posts matching any of the simple keywords -- these keywords do not have to be stored 
    */
    public List<UserFeed> getPosts(List<String> simpleKeywords) {     
		if (simpleKeywords.size() == 0) {
			return new List<UserFeed>();
		}
		
		//Cannot query FeedPost directly -- have to go through [Type]Feed.
		String postQuery = 'SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, ' +
			' FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title, FeedPost.CreatedDate From UserFeed Where ';
		
		Integer i = 0;
		
		for (String currentKw : simpleKeywords) {
			postQuery += ' ( FeedPost.Body like \'%' + String.escapeSingleQuotes(currentKw) +'%\' ) ';
			i++;
			if (i < simpleKeywords.size()) {
				postQuery += ' OR ';
			}	 
		}
		
		postQuery += ' Order By FeedPost.CreatedDate DESC LIMIT 100';
		
		List<UserFeed> ret = Database.query(postQuery);
        
        return ret;
        
    }
    
    /*
    Test methods and utilities
    */
    
    static void addSingleKeyword(String kw) {

        Chatter_Keywords__c kw1 = new Chatter_Keywords__c();
        kw1.Name = kw;
        insert kw1;
    	
    }
    
    /*
    Creates a set of keywords for a test user and returns them.
    */
    static TestMethod void testGetMyKeywords() {
       	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
	        ChatterKeywordQuery.addSingleKeyword('one');
	        ChatterKeywordQuery query = new ChatterKeywordQuery();
	        List<Chatter_Keywords__c> kwList = query.getMyKeywords();        
	        System.assert(kwList.size() == 1);
		}   
    }
    
    /*
    tests to be sure we can get these as a String
    */
    static TestMethod void testGetMyKeywordsAsString() {
       	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
	        ChatterKeywordQuery.addSingleKeyword('one');
	        ChatterKeywordQuery query = new ChatterKeywordQuery();
	        List<String> strings = query.getSimpleKeywords(query.getMyKeywords());     
	        System.assert(strings.size() == 1);
		}   
    }

	/*
	ensures we get no data if we have no keywords configured.
	*/
    static TestMethod void testGetPostsNoKeywords() {
       	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
	        ChatterKeywordQuery query = new ChatterKeywordQuery();
			List<UserFeed> results = query.getPosts();
			System.assert(results.size() == 0);
		}   
    }
    
    /*
    given a single keyword and a single post, make sure we get a result
    */
    static TestMethod void testGetPostsSimple() {
    	
    	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
			
	    	String word1 = TestUtility.createRandomWord();
	    	
	        ChatterKeywordQuery.addSingleKeyword(word1);
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is post ' + word1 + ' of many');
			ChatterKeywordQuery query = new ChatterKeywordQuery();
			List<UserFeed> ret = query.getPosts();
	        System.assert(ret.size() == 1);
    	}
    }
    
    /*
    test to be sure it workds with a single string
    */
    static TestMethod void testGetPostsSingleKeyword() {
    	
    	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
			
	    	String word1 = TestUtility.createRandomWord();
	    	String word2 = TestUtility.createRandomWord();
	    
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is post ' + word1 + ' of many');
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is post ' + word2 + ' of many');
			ChatterKeywordQuery query = new ChatterKeywordQuery();
			List<UserFeed> ret = query.getPosts(word1);
	        System.assert(ret.size() == 1);
    	}
    }

	/*
	test to be sure we're getting the right number of results with more KWs and that no posts are returned in dupliciate
	*/
    static TestMethod void testGetPostsComplex() {
    	
    	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
	    	String word1 = TestUtility.createRandomWord();
	    	String word2 = TestUtility.createRandomWord();
	    	String word3 = TestUtility.createRandomWord();
	    	String word4 = TestUtility.createRandomWord();
	    	
	        ChatterKeywordQuery.addSingleKeyword(word1);
	
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is ' + word4 +'  ' + word1 + ' of many');
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is ' + word4 +' ' + word2 + ' of many');
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is ' + word4 +' ' + word3 + ' of many');
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is a sentence with no keywords');
	
			ChatterKeywordQuery query = new ChatterKeywordQuery();
			
			List<UserFeed> ret = query.getPosts();
	        System.assert(ret.size() == 1);
	        
	        ChatterKeywordQuery.addSingleKeyword(word2);
	
			ret = query.getPosts();
	        System.assert(ret.size() == 2);
	        
	        ChatterKeywordQuery.addSingleKeyword(word3);
	
			ret = query.getPosts();
	        System.assert(ret.size() == 3);
	        
	        ChatterKeywordQuery.addSingleKeyword(word4);
	
			ret = query.getPosts();
	        System.assert(ret.size() == 3);
		}
    }
   
	/*
	be sure we're getting posts from users other than ourselves.
	*/   
    static TestMethod void testGetPostsMultipleUsers() {
    	
    	User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
	    	String word1 = TestUtility.createRandomWord();
	
	    	
	        ChatterKeywordQuery.addSingleKeyword(word1);
	
			TestUtility.createFeedPost(UserInfo.getUserId(), 'this is a title', 'here is post ' + word1 + ' of many');
	
			User testUser2 = TestUtility.createTestUser();
			 
			ChatterKeywordQuery query = new ChatterKeywordQuery();
			TestUtility.createFeedPost(testUser2.Id, 'this is a title', 'user2 here is post ' + word1 + ' of many');
			
			List<UserFeed> ret = query.getPosts();
	        System.assert(ret.size() == 2);
		}
    }

    
}