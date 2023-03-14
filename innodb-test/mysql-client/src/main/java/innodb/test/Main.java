package innodb.test;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class Main {
    private static HikariConfig config = new HikariConfig();
    private static HikariDataSource ds;

    public static void main(String[] args) throws SQLException, IOException {

        /*
        JDBC_URL=jdbc:mysql://mysql.local:3306/usersdb
        JDBC_USER=user
        JDBC_PASS=somepass
        */

        System.out.println("connecting mysql " + System.getenv("JDBC_URL"));

        config.setJdbcUrl( System.getenv("JDBC_URL") );//"" );
        config.setUsername( System.getenv("JDBC_USER") ); //"" );
        config.setPassword( System.getenv("JDBC_PASS") ); //"somepass" );
        config.addDataSourceProperty( "cachePrepStmts" , "true" );
        config.addDataSourceProperty( "prepStmtCacheSize" , "250" );
        config.addDataSourceProperty( "prepStmtCacheSqlLimit" , "2048" );
        ds = new HikariDataSource( config );

        String ddl = readResource("/ddl.sql");
        try(Connection conn = ds.getConnection()) {
            try (Statement stmt = conn.createStatement()) {
                stmt.execute(ddl);
                stmt.execute("INSERT INTO usersdb.tb_users VALUES (null, 'someemail@somedomain.com', 'Some User', 'asd123')");

                var rs = stmt.executeQuery("SELECT * FROM tb_users");
                while (rs.next()) {
                    System.out.println(rs.getString("name"));
                }
            }
        }
    }

    private static String readResource(String url) throws IOException {
        try(var is = Main.class.getResourceAsStream(url)) {
            return new String(new BufferedInputStream(is).readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}