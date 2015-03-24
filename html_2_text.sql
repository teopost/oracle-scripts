-- select pkg_html.to_text(testo) from api_msg_messages
-- where user_id = '1122530'

CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED HTML as import javax.swing.text.BadLocationException;
    import javax.swing.text.Document;
    import javax.swing.text.html.HTMLEditorKit;
    import java.io.*;
    import java.io.File;

    import java.security.AccessControlException;
    import java.sql.*;
    import oracle.sql.driver.*;
    import oracle.sql.*;


    public class HTML extends Object
    {
        private static CLOB outCLOB;
    private static String retVal;
    private static int i;
    private static String p_in;

    public static CLOB to_text(CLOB p_ins) 
    
    throws IOException, BadLocationException, AccessControlException, SQLException {
      if (p_ins == null)
      {
            Connection conn = DriverManager.getConnection("jdbc:default:connection:");
            outCLOB = CLOB.createTemporary((oracle.jdbc.OracleConnectionWrapper) conn, true, CLOB.DURATION_SESSION);
            i = outCLOB.setString(1, "");
            return outCLOB;
      }
         
             
      p_in = clobToString(p_ins).trim();
        if (p_in != null) {
            HTMLEditorKit kit = new HTMLEditorKit();
            Document doc = kit.createDefaultDocument();
            doc.putProperty("IgnoreCharsetDirective", new Boolean(true));
            kit.read(new StringReader(p_in), doc, 0);
            retVal = doc.getText(0, doc.getLength());
            Connection conn = DriverManager.getConnection("jdbc:default:connection:");
            outCLOB = CLOB.createTemporary((oracle.jdbc.OracleConnectionWrapper) conn, true, CLOB.DURATION_SESSION);
            i = outCLOB.setString(1, retVal);
            return outCLOB;
        } else
        {
            Connection conn = DriverManager.getConnection("jdbc:default:connection:");
            outCLOB = CLOB.createTemporary((oracle.jdbc.OracleConnectionWrapper) conn, true, CLOB.DURATION_SESSION);
            i = outCLOB.setString(1, "");
            return outCLOB;
            }
    }

    static private String clobToString(java.sql.Clob data) {
        final StringBuilder sb = new StringBuilder();
        try {
            final Reader reader = data.getCharacterStream();
            final BufferedReader br = new BufferedReader(reader);
            int b;
            while (-1 != (b = br.read())) {
                sb.append((char) b);
            }
            br.close();
        } catch (SQLException e) {
            return e.toString();
        } catch (IOException e) {
            return e.toString();
        }
        return sb.toString();
    }
    }

/


CREATE OR REPLACE PACKAGE pkg_html
     IS
         FUNCTION to_text ( html_in IN CLOB )
         RETURN CLOB
         IS
            language java
            name 'HTML.to_text( oracle.sql.CLOB ) return oracle.sql.CLOB';

END pkg_html;
/

