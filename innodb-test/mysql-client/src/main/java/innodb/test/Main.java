package innodb.test;

import com.github.javafaker.Faker;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

class User {
    int id;
    String email;
    String name;
    String password;

    public User(String email, String name, String password) {
        this.email = email;
        this.name = name;
        this.password = password;
    }
}

public class Main {
    private static HikariConfig config = new HikariConfig();
    private static HikariDataSource ds;

    /**
        JDBC_URL=jdbc:mysql://mysql.local:3306/usersdb
        JDBC_USER=user
        JDBC_PASS=somepass
    */
    public static void main(String[] args) throws SQLException, IOException {

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
            }
        }

        var exec = Executors.newSingleThreadScheduledExecutor();
        exec.scheduleAtFixedRate(() -> insertUser(ds), 1000,1000, TimeUnit.MILLISECONDS);
    }

    public static void insertUser(DataSource ds) {
        try (var conn = ds.getConnection()) {
            var f = Faker.instance();
            var user = new User(f.internet().emailAddress(), f.name().name(), f.bothify("???????") );
            String sql = "INSERT INTO usersdb.tb_users VALUES (null, ?, ?, ?)";
            var pStmt = conn.prepareStatement(sql);
            pStmt.setString(1, user.email);
            pStmt.setString(2, user.name);
            pStmt.setString(3, user.password);
            pStmt.execute();

            pStmt = conn.prepareStatement("SELECT * FROM tb_users WHERE email = ?");
            pStmt.setString(1, user.email);
            var rs = pStmt.executeQuery();
            while (rs.next()) {
                System.out.println("Name for " + user.email + ": " + rs.getString("name"));
            }
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
        }
    }

    private static String readResource(String url) throws IOException {
        try(var is = Main.class.getResourceAsStream(url)) {
            return new String(new BufferedInputStream(is).readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}