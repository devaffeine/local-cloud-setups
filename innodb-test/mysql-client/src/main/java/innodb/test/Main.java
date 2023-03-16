package innodb.test;

import com.github.javafaker.Faker;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
import javax.xml.crypto.Data;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
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

    private static DataSource ds;
    private static DataSource roDs;
    /**
     * JDBC_URL=jdbc:mysql://mysql.local:3306/usersdb
     * JDBC_URL_RO=jdbc:mysql://mysql.local:3306/usersdb
     * JDBC_USER=user
     * JDBC_PASS=somepass
     */
    public static void main(String[] args) throws SQLException, IOException {
        System.out.println("connecting mysql " + System.getenv("JDBC_URL"));

        ds = createDataSourceFromEnv("JDBC_URL", "JDBC_USER", "JDBC_PASS");
        roDs = createDataSourceFromEnv("JDBC_URL_RO", "JDBC_USER", "JDBC_PASS");

        execDdl(ds);
        var exec = Executors.newSingleThreadScheduledExecutor();
        exec.scheduleAtFixedRate(() -> insertUser(ds), 1000, 1000, TimeUnit.MILLISECONDS);
        exec.scheduleAtFixedRate(() -> readUsers(ds, roDs), 100, 100, TimeUnit.MILLISECONDS);
    }

    private static void execDdl(DataSource ds) throws IOException, SQLException {
        String ddl = readResource("/ddl.sql");
        try (Connection conn = ds.getConnection()) {
            try (Statement stmt = conn.createStatement()) {
                stmt.execute(ddl);
            }
        }
    }

    private static HikariDataSource createDataSourceFromEnv(String jdbcUrl, String jdbcUser, String jdbcPass) {
        var config = new HikariConfig();
        config.setJdbcUrl(System.getenv(jdbcUrl));
        config.setUsername(System.getenv(jdbcUser));
        config.setPassword(System.getenv(jdbcPass));
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        return new HikariDataSource(config);
    }

    public static void readUsers(DataSource ds, DataSource roDs) {
        try {
            int count = countUsers(ds);
            int roCount = countUsers(roDs);
            if(count != roCount) {
                System.err.println("err: counts dont match: " + count + " != ro: " + roCount);
            }
            else {
                System.out.println("counts: " + count + " ro: " + roCount);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    private static int countUsers(DataSource ds) throws SQLException {
        try (var conn = ds.getConnection()) {
            try (var pStmt = conn.prepareStatement("SELECT COUNT(*) FROM tb_users")) {
                try (var rs = pStmt.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
        }
        return 0;
    }

    public static void insertUser(DataSource ds) {
        try (var conn = ds.getConnection()) {
            var f = Faker.instance();
            var user = new User(f.internet().emailAddress(), f.name().name(), f.bothify("???????"));
            String sql = "INSERT INTO usersdb.tb_users VALUES (null, ?, ?, ?)";
            try (var pStmt = conn.prepareStatement(sql)) {
                pStmt.setString(1, user.email);
                pStmt.setString(2, user.name);
                pStmt.setString(3, user.password);
                pStmt.execute();
            }

            try (var pStmt = conn.prepareStatement("SELECT * FROM tb_users WHERE email = ?")) {
                pStmt.setString(1, user.email);
                try (var rs = pStmt.executeQuery()) {
                    while (rs.next()) {
                        System.out.println("Name for " + user.email + ": " + rs.getString("name"));
                    }
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    private static String readResource(String url) throws IOException {
        try (var is = Main.class.getResourceAsStream(url)) {
            return new String(new BufferedInputStream(is).readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}