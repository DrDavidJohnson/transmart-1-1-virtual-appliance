 /**
 * Configuration for database connection - this file will be loaded 
 * by the tranSMART application when the tomcat is restarted
 */

dataSource {

            driverClassName ="org.postgresql.Driver"         

            url = "jdbc:postgresql://localhost:5432/transmart"             // AWS GPL Database

            username = "biomart_user"

            password = "biomart_user"

            dialect = "org.hibernate.dialect.PostgreSQLDialect"

            //loggingSql = true
	    	//logSql = true

            //formatSql = true

}


hibernate {
	// hibernate cache config
	cache.use_second_level_cache=true
	//turn on query cache
	cache.use_query_cache=true
	cache.provider_class='org.hibernate.cache.EhCacheProvider'
	// pool size
	connection.pool_size=30
	//format_sql = true
	//use_sql_comments = true
}

