/*
	reid.carlberg@salesforce.com
*/
public with sharing class ChatterFilterQuery {

	public List<UserFeed> getFilteredPosts(String myFilter) { 
		
		List<UserFeed> userFeeds = null;
		
		
		if (myFilter == null || myFilter.trim().length() == 0) {
			userFeeds = getPosts();
		} else {
			userFeeds = getPosts(myFilter);
		}
		return userFeeds;
	}
	public List<Chatter_Filter__c> getFilters() {
	
		Id userId = UserInfo.getUserId();
		
		List<Chatter_Filter__c> ret = [Select Id, Name, (Select Id, Type__c, Keyword__c FROM Chatter_Filter_Conditions__r) 
			FROM Chatter_Filter__c WHERE OwnerId =: userId];
			
		return ret;
	}
	
	public List<Chatter_Filter__c> getFilters(Id targetId) {
	
		Id userId = UserInfo.getUserId();
		
		List<Chatter_Filter__c> ret = [Select Id, Name, (Select Id, Type__c, Keyword__c FROM Chatter_Filter_Conditions__r) 
			FROM Chatter_Filter__c WHERE OwnerId =: userId And Id =: targetId];
			
		return ret;
	}
	
	public List<UserFeed> getPosts(String target) {
		Id targetId = null;
		
		try {
			targetId = target;
		} catch (Exception e) {
			System.debug('couldnt covert to an id ' + target);
			return this.getPosts();
		}
		
		return (this.getPosts(this.getFilters(targetId)));
		
		
		
		
	}
	
	public List<UserFeed> getPosts() {
		
		List<Chatter_Filter__c> myFilters = this.getFilters();
		
		return getPosts(myFilters);
	
	}


	public List<UserFeed> getPosts(List<Chatter_Filter__c> myFilters) {
		
		
		if (myFilters == null || myFilters.size() == 0) {
			return new List<UserFeed>();
		}
		
		String postQuery = 'SELECT Id, Type, CreatedBy.FirstName, CreatedBy.LastName, ParentId, Parent.Name, ' +
			' FeedPost.Id, FeedPost.Type, FeedPost.Body, FeedPost.Title, FeedPost.CreatedDate From UserFeed Where ';
		
		Integer filterCounter = 0;
		
		for (Chatter_Filter__c currentFilter : myFilters) {
			if (currentFilter.Chatter_Filter_Conditions__r.size() > 0) {
				postQuery += '( ';
				filterCounter++;
				Integer conditionCounter = 0;
				String likeModifier = '';
				
				for (Chatter_Filter_Condition__c currentCondition : currentFilter.Chatter_Filter_Conditions__r) {
					if (currentCondition.Type__c == 'includes') {
						likeModifier = '';
					} else {
						likeModifier = ' not ';
					}
					String conditionKeyword = currentCondition.Keyword__c;
					conditionKeyword = conditionKeyword.replace('\'', '\\\'');
					postQuery += ' ( ' + likeModifier + ' FeedPost.Body like \'%' + conditionKeyword +'%\' ) ';
					conditionCounter++;
					if (conditionCounter < currentFilter.Chatter_Filter_Conditions__r.size()) {
						postQuery += ' AND ';
					}
				}
				postQuery += ') ';
				if (filterCounter < myFilters.size()) {
					postQuery += ' OR ';
				}	 				
				
			}
		}
		
		postQuery += ' Order By FeedPost.CreatedDate DESC LIMIT 100';
		
		System.debug(postQuery);
		
		List<UserFeed> ret = Database.query(postQuery);
        
        return ret;
		
	}

	static Chatter_Filter__c createFilter(String name) {
		Chatter_Filter__c newFilter = new Chatter_Filter__c();
		newFilter.Name = name;
		insert newFilter;
		return newFilter;
	} 
	
	static Chatter_Filter_Condition__c createCondition(Chatter_Filter__c filter, Boolean includes, String value) {
		
		Chatter_Filter_Condition__c newCondition = new Chatter_Filter_Condition__c();
		newCondition.Chatter_Filter__c = filter.id;
		if (includes) {
			newCondition.Type__c = 'includes';
		} else {
			newCondition.Type__c = 'excludes';
		}
		newCondition.Keyword__c = value;
		insert newCondition;
		
		return newCondition;
		
	}
	
	static TestMethod void testGetFilters() {
		
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			System.assert(filter.id != null);
			
			String wordOne = TestUtility.createRandomWord();
			String wordTwo = TestUtility.createRandomWord();
			
			Chatter_Filter_Condition__c cond1 = ChatterFilterQuery.createCondition(filter, TRUE, wordOne);
			Chatter_Filter_Condition__c cond2 = ChatterFilterQuery.createCondition(filter, TRUE, wordTwo);
			
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			List<Chatter_Filter__c> filters = query.getFilters();
			System.assert(filters.size() == 1);
			
			Chatter_Filter__c currentFilter = filters.get(0);
			System.assert(currentFilter.Chatter_Filter_Conditions__r != null);
			System.assert(currentFilter.Chatter_Filter_Conditions__r.size() == 2);
			
		}
		
	}
	
	static TestMethod void testGetSingleFilter() {
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			System.assert(filter.id != null);
			
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			List<Chatter_Filter__c> filters = query.getFilters(filter.id);
			System.assert(filters.size() == 1);
			
			Chatter_Filter__c currentFilter = filters.get(0); 
			System.assert(currentFilter.id == filter.id);
			
			
		}
	}

	static TestMethod void testFilteredPosts() {
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			String word1 = TestUtility.createRandomWord();
			String word2 = TestUtility.createRandomWord();
			ChatterFilterQuery.createCondition(filter, TRUE, word1);
			ChatterFilterQuery.createCondition(filter, TRUE, word2);

			Chatter_Filter__c filter2 = ChatterFilterQuery.createFilter('filter2');
			String word3 = TestUtility.createRandomWord();
			String word4 = TestUtility.createRandomWord();
			ChatterFilterQuery.createCondition(filter2, TRUE, word3);
			ChatterFilterQuery.createCondition(filter2, TRUE, word4);
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it');
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word3 + ' and ' + word4 + ' in it');
			
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			List<UserFeed> posts = query.getFilteredPosts(null);

			System.assert(posts != null);
			System.assert(posts.size() == 2);
			
			List<UserFeed> posts2 = query.getFilteredPosts(''+filter.id);

			System.assert(posts2 != null);
			System.assert(posts2.size() == 1);
			
		}
	}

	
	static TestMethod void testGetPostsSingleFilter() {
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			String word1 = TestUtility.createRandomWord();
			String word2 = TestUtility.createRandomWord();
			ChatterFilterQuery.createCondition(filter, TRUE, word1);
			ChatterFilterQuery.createCondition(filter, TRUE, word2);
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it');
			
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			List<UserFeed> posts = query.getPosts(''+filter.id);

			System.assert(posts != null);
			System.assert(posts.size() == 1);
			
			//test for bad id
			List<UserFeed> posts2 = query.getPosts('BadId'+filter.id);

			System.assert(posts2 != null);
			System.assert(posts2.size() == 1);
			
		}
	}
	
	static TestMethod void testGetPostsSimple() {
		
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
			
			String word1 = TestUtility.createRandomWord();
			String word2 = TestUtility.createRandomWord();
			String word3 = TestUtility.createRandomWord();
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			System.assert(filter.id != null);
			
			ChatterFilterQuery.createCondition(filter, TRUE, word1);
			ChatterFilterQuery.createCondition(filter, TRUE, word2);

			TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it');
						
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			//first be sure we get empty when we should
			List<Chatter_Filter__c> emptyList = new List<Chatter_Filter__c>();
			List<UserFeed> emptyResult = query.getPosts(emptyList);
			System.assert(emptyResult.size() == 0);
			
			//ok on to the rest
			List<UserFeed> result = query.getPosts();
			
			System.assert(result.size() == 1);
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has only ' + word3 +' in it');
			
			result = query.getPosts();
			System.assert(result.size() == 1);
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has only ' + word1 + ' in it');
			result = query.getPosts();
			System.assert(result.size() == 1);
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has ' + word1 + ', ' + word2 + ' and ' + word3 + ' in it');
			result = query.getPosts();
			System.assert(result.size() == 2);
			
			ChatterFilterQuery.createCondition(filter, FALSE, word3);
			result = query.getPosts();
			System.assert(result.size() == 1);
			
		}
		
	}
	
	static TestMethod void testGetPostsComplex() {
		
		User testUser = TestUtility.createTestUser();
		
		System.runAs(testUser) {
		
			
			String word1 = TestUtility.createRandomWord();
			String word2 = TestUtility.createRandomWord();
			String word3 = TestUtility.createRandomWord();
			String word4= TestUtility.createRandomWord();
		
			Chatter_Filter__c filter = ChatterFilterQuery.createFilter('filter1');
			ChatterFilterQuery.createCondition(filter, TRUE, word1);
			ChatterFilterQuery.createCondition(filter, TRUE, word2);
			ChatterFilterQuery.createCondition(filter, False, word3);
			
			Chatter_Filter__c filter2 = ChatterFilterQuery.createFilter('filter2');
			ChatterFilterQuery.createCondition(filter2, TRUE, word2);
			ChatterFilterQuery.createCondition(filter2, TRUE, word3);
			ChatterFilterQuery.createCondition(filter2, FALSE, word4);

			User testUser2 = TestUtility.createTestUser();
			
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has word ' + word1 + '  in it'); // no
			TestUtility.createFeedPost(testUser.Id, 'title', 'this has both words ' + word1 + ' and ' + word2 + ' in it'); //filter1
			TestUtility.createFeedPost(testUser2.Id, 'title', 'this has both words ' + word2 + ' and ' + word3 + ' in it'); //filter two
			TestUtility.createFeedPost(testUser2.Id, 'title', 'this has words ' + word1 + ', ' + word2 + ' and ' + word3 + ' in it'); //filter 1 no filter 2 yes
			TestUtility.createFeedPost(testUser2.Id, 'title', 'this has words ' + word1 + ' ' + word2 + ' ' + word3 + ' and ' + word4 + ' in it'); //filter 1 no filter 2 no
						
			ChatterFilterQuery query = new ChatterFilterQuery();
			
			List<UserFeed> result = query.getPosts();
			System.assert(result.size() == 3);
			
			
		}
		
	}
	
	
}