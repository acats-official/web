<metadata>
 <datum name=description value="">
 <datum name=http-content-type value="roxen/pike">
 <datum name=keywords value="drink search drinks acats aristocats">
 <datum name=language value="en">
 <datum name=title value="Acats.org - Drink search">
</metadata>
inherit "roxenlib";

object db;
object requestID;
int loginID;
string loginName;
string redirectTo = "";

#define SQL_DATABASE "mysql://acats:tinto2760@service/acats"

#define P_PREFERENCES "preferences"
#define P_REGISTER "register"
#define P_LOGIN "login"
#define P_LOGOUT "logout"
#define P_GETPASSWORD "getpassword"
#define P_SHOWDRINK "showdrink"
#define P_SHOWDRINK_PRINTABLE "showdrinkP"
#define P_SHOWUSER "showuser"
#define P_SHOWINGREDIENT "showingredient"
#define P_MAINSEARCH "mainsearch"
#define P_NAMESEARCH "namesearch"
#define P_CRITERIASEARCH "criteriasearch"
#define P_INGREDIENTSEARCH "ingredientsearch"
#define P_SENDDRINK "senddrink"
#define P_SEARCHHELP "searchhelp"
#define MAX_DRINKS 25

array
GetSearchArray(string inp)
{
  array temp = inp / "\"";
  array temp2 = ({});
  array output = ({});
  int ordinary = 1;
  string addToNext = "";
  
  for(int i = 0; i < sizeof(temp); i++) {
    if(ordinary) {
      while(sizeof(temp[i]) && temp[i][0] == " ")
        temp[i] = temp[i][1..];
      while(sizeof(temp[i]) && temp[i][-1] == " ")
        temp[i] = temp[i][..-2];
      if(sizeof(temp[i]))
        temp2 += temp[i] / " ";
    } else {
      temp2 += ({temp[i]});
    }
    ordinary = 1 - ordinary;
  }
  for(int i = 0; i < sizeof(temp2); i++) {
    switch(temp2[i]) {
      case "+":
      case "-":
        addToNext = temp2[i];
        break;
      case "":
        break;
      default:
        output += ({addToNext + temp2[i]});
        addToNext = "";
    }
  }
  return output;
}

string
NameSearchPage()
{
  string s = "";
  string q = "";
  string q2;
  string q3;
  mixed err;
  array a;
  array tempArr;
  int newSearch = 1;
  string drinkname = "";
  string ingredients = "";
  string notString = "";
  string mustString = "";
  array(string) normalArray = ({});

  if(stringp(requestID->variables["drinkname"]))
    drinkname = requestID->variables["drinkname"];
  if(stringp(requestID->variables["ingredients"]))
    ingredients = requestID->variables["ingredients"];

  s += H1("The Ultimate Drink Search") +
       H2("Search drinks by name and/or ingredientname");

  if(stringp(requestID->variables["searchbutton.x"])) {

    // Fix the search arrays
    array h  = GetSearchArray(drinkname);
    array h2 = GetSearchArray(ingredients);

    // First create mustArray
    q = "SELECT id FROM drink WHERE";
    int first = 1;
    for(int i = 0; i < sizeof(h); i++) {
      if(h[i][0] == '+') {
        if(first)
          q += " name LIKE '%" + h[i][1..] + "%'";
        else
          q += " AND name LIKE '%" + h[i][1..] + "%'";
        first = 0;
      }
    }
    if(first == 0) {
      err = catch(a = db->query(q));
      //s += q + "\n";
      if (err)
        error("Query failed: " + q + ": " + err[0]);
      for(int i = 0; i < sizeof(a); i++) {
        if(mustString == "")
          mustString += a[i]->id;
        else
          mustString += "," + a[i]->id;
      }
    }
    q2 = "";
    for(int i = 0; i < sizeof(h2); i++) {
      if(h2[i][0] == '+') {
        q = "SELECT id FROM ingredient WHERE name LIKE '%" + h2[i][1..] + "%'";
        err = catch(a = db->query(q));
        if (err)
          error("Query failed: " + q + ": " + err[0]);
        for(int i = 0; i < sizeof(a); i++) {
          if(q2 == "")
            q2 = "SELECT DISTINCT drink FROM drinkingredient WHERE ingredient IN (" + a[i]->id;
          else
            q2 += "," + a[i]->id;
        }
      }
    }
    if(q2 != "") {
      q2 += ")";
      err = catch(a = db->query(q2));
      //s += q2 + "\n";
      if (err)
        error("Query failed: " + q2 + ": " + err[0]);
      for(int i = 0; i < sizeof(a); i++) {
        if(mustString == "")
          mustString += a[i]->drink;
        else
          mustString += "," + a[i]->drink;
      }
    }

    // Next, create notArray
    q = "SELECT id FROM drink WHERE 1=0";
    for(int i = 0; i < sizeof(h); i++) {
      if(h[i][0] == '-') {
        q += " OR name LIKE '%" + h[i][1..] + "%'";
      }
    }
    err = catch(a = db->query(q));
    //s += q + "\n";
    if (err)
      error("Query failed: " + q + ": " + err[0]);
    for(int i = 0; i < sizeof(a); i++) {
      if(notString == "")
        notString += a[i]->id;
      else
        notString += "," + a[i]->id;
    }
    q2 = "";
    for(int i = 0; i < sizeof(h2); i++) {
      if(h2[i][0] == '-') {
        q = "SELECT id FROM ingredient WHERE name LIKE '%" + h2[i][1..] + "%'";
        err = catch(a = db->query(q));
        if (err)
          error("Query failed: " + q + ": " + err[0]);
        for(int i = 0; i < sizeof(a); i++) {
          if(q2 == "")
            q2 = "SELECT DISTINCT drink FROM drinkingredient WHERE ingredient IN (" + a[i]->id;
          else
            q2 += "," + a[i]->id;
        }
      }
    }
    if(q2 != "") {
      q2 += ")";
      err = catch(a = db->query(q2));
      //s += q2 + "\n";
      if (err)
        error("Query failed: " + q2 + ": " + err[0]);
      for(int i = 0; i < sizeof(a); i++) {
        if(notString == "")
          notString += a[i]->drink;
        else
          notString += "," + a[i]->drink;
      }
    }

    // Now, create normal arrays
    int index = 0;
    for(int i = 0; i < sizeof(h); i++) {
      if((h[i][0] != '-') && (h[i][0] != '+')) {
        q = "SELECT id FROM drink WHERE name LIKE '%" + h[i] + "%'";
        err = catch(a = db->query(q));
        //s += q + "\n";
        if (err)
          error("Query failed: " + q + ": " + err[0]);
        for(int i = 0; i < sizeof(a); i++) {
          if(index == sizeof(normalArray))
            normalArray += ({a[i]->id});
          else
            normalArray[index] += "," + a[i]->id;
        }
        index++;
      }
    }
    for(int i = 0; i < sizeof(h2); i++) {
      if((h2[i][0] != '-') && (h2[i][0] != '+')) {
        q = "SELECT id FROM ingredient WHERE name LIKE '%" + h2[i][1..] + "%'";
        err = catch(a = db->query(q));
        if (err)
          error("Query failed: " + q + ": " + err[0]);
        q2 = "";
        for(int i = 0; i < sizeof(a); i++) {
          if(q2 == "")
            q2 = "SELECT DISTINCT drink FROM drinkingredient WHERE ingredient IN (" + a[i]->id;
          else
            q2 += "," + a[i]->id;
        }
        if(q2 != "") {
          q2 += ")";
          err = catch(a = db->query(q2));
          //s += q2 + "\n";
          if (err)
            error("Query failed: " + q2 + ": " + err[0]);
          for(int i = 0; i < sizeof(a); i++) {
            if(index == sizeof(normalArray))
              normalArray += ({a[i]->drink});
            else
              normalArray[index] += "," + a[i]->drink;
          }
          index++;
        }
      }
    }

    // Finally, create the big question
    q = " AS score FROM drink,drinktype WHERE drink.drinktype=drinktype.id";
    if(sizeof(normalArray)) {
      q += " AND (1=0";
      for(int i = 0; i < sizeof(normalArray); i++) {
        q = " + (drink.id IN (" + normalArray[i] + "))" + q + " OR drink.id IN (" + normalArray[i] + ")";
      }
      q += ")";
    }
    //q = "SELECT drink.id AS id, drink.name AS name, drinktype.name as type FROM drink,drinktype WHERE drink.drinktype=drinktype.id AND ";
    q = "SELECT drink.id AS id, drink.name AS name, drinktype.name as type, 0" + q;
    if(mustString != "")
      q += " AND drink.id IN (" + mustString + ")";
    if(notString != "")
      q += " AND drink.id NOT IN (" + notString + ")";
    q += " ORDER BY score DESC, drink.name";
    //if(stringp(requestID->variables["startdrink"]))
    //  q += " LIMIT " + requestID->variables["startdrink"] + ",20";
    //else
    //  q += " LIMIT 20";

    // and "pop" it!
    err = catch(a = db->query(q));
    //s += q + "<br>";
    if (err)
      error("Query failed: " + q + ": " + err[0]);

    // Display Results
    s += "<table width=\"100%\" rules=none border=0 align=center cellspacing=0 cellpadding=0 vspace=0 hspace=0>\n";
    s += "<tr>\n";
    s += TD_Small("", "hejsan");
    int to = (int)requestID->variables["startdrink"] + MAX_DRINKS;
    if(sizeof(a) < to)
      to = sizeof(a);
    string s2 = "";
    if((int)requestID->variables["startdrink"] != 0)
      s2 += sprintf("<A HREF=\"?startdrink=%d&drinkname=%s&ingredients=%s&searchbutton.x=1\"><<</A> ", 
                    (int)requestID->variables["startdrink"] - MAX_DRINKS,
                    drinkname,
                    ingredients);
    s2 += sprintf("search result %d-%d of %d", (int)requestID->variables["startdrink"] + 1, to, sizeof(a));
    if(to != sizeof(a))
      s2 += sprintf(" <A HREF=\"?startdrink=%d&drinkname=%s&ingredients=%s&searchbutton.x=1\">>></A>", 
                    (int)requestID->variables["startdrink"] + MAX_DRINKS,
                    drinkname,
                    ingredients);
    s += TD_Small("align=\"right\"", s2);
    s += "</tr>\n";
    s += "</table>\n";
    s += "<table width=\"100%\" rules=none frame=border border=1 align=center cellspacing=0 cellpadding=2 vspace=2 hspace=2>\n";
    for(int i = (int)requestID->variables["startdrink"]; i < to; i++) {
      string name = roxen_encode(a[i]->name, "html");
      string id = roxen_encode(a[i]->id, "html");
      string type = roxen_encode(a[i]->type, "html");
      s += " <tr>\n"
           + TD_Normal("bgcolor=\"#006622\"", "<A HREF=\"?page=" + P_SHOWDRINK + "&id=" + id + "\">" + name + "</A>")
           + TD_Normal("bgcolor=\"#007733\"", type) +
           " </tr>\n";
    }
    s += "</table>\n";
    //s += q + "\n";
   
    
    /*q = "SELECT drink.id AS id, drink.name AS name, drinktype.name as type FROM drink,drinktype WHERE drink.drinktype=drinktype.id AND ";
    if(containsPlus == 0) {
      q += "(";
      for(int i = 0; i < sizeof(h); i++) {
        if(h[i][0] != '+' && h[i][0] != '-') {
          q += "drink.name LIKE '%" + h[i] + "%' OR ";
        }
      }
      if(q[-1] == '(')
        q += "1=1) AND ";
      else
        q += "0=1) AND ";
    }
    for(int i = 0; i < sizeof(h); i++) {
      if(h[i][0] == '+') {
        q += "drink.name LIKE '%" + h[i][1..] + "%' AND ";
      }
      else if(h[i][0] == '-') {
        q += "drink.name NOT LIKE '%" + h[i][1..] + "%' AND ";
      }
    }
    containsPlus = 0;
    h = GetSearchArray(ingredients);
    for(int i = 0; i < sizeof(h); i++) {
      if(h[i][0] == '+') {
        containsPlus = 1;
      }
    }
    q2 = "SELECT DISTINCT drink FROM drinkingredient WHERE ";
    if(containsPlus == 0) {
      q2 += "(";
      for(int i = 0; i < sizeof(h); i++) {
        if(h[i][0] != '+' && h[i][0] != '-') {
          q3 = "SELECT id FROM ingredient WHERE name LIKE '%" + h[i] + "%'";
          err = catch(a = db->query(q3));
          if (err)
            error("Query failed: "+q3+": "+err[0]);
          tempArr = ({});
          for(int i = 0; i < sizeof(a); i++)
            tempArr += ({a[i]->id});
          q2 += "ingredient IN (" + tempArr * ", " + ") OR ";
        }
      }
      q2 += "0=1) AND ";
    }
    for(int i = 0; i < sizeof(h); i++) {
      if(h[i][0] == '+') {
        q3 = "SELECT id FROM ingredient WHERE name LIKE '%" + h[i][1..] + "%'";
        err = catch(a = db->query(q3));
        if (err)
          error("Query failed: "+q3+": "+err[0]);
        tempArr = ({});
        for(int i = 0; i < sizeof(a); i++)
          tempArr += ({a[i]->id});
        tempArr += ({"-1"});
        q2 += "ingredient IN (" + tempArr * ", " + ") AND ";
      }
      else if(h[i][0] == '-') {
        q3 = "SELECT id FROM ingredient WHERE name LIKE '%" + h[i][1..] + "%'";
        err = catch(a = db->query(q3));
        if (err)
          error("Query failed: "+q3+": "+err[0]);
        tempArr = ({});
        for(int i = 0; i < sizeof(a); i++)
          tempArr += ({a[i]->id});
        tempArr += ({"-1"});
        q2 += "ingredient NOT IN (" + tempArr * ", " + ") AND ";
      }
    }
    q2 += "1=1";
    err = catch(a = db->query(q2));
    if (err)
      error("Query failed: "+q2+": "+err[0]);
    tempArr = ({});
    for(int i = 0; i < sizeof(a); i++)
      tempArr += ({a[i]->drink});
    if(sizeof(a)) {
      q += "drink.id IN (" + tempArr * ", " + ")";
    } else {
      q += "1=1";
    }
    if(q == "SELECT drink.id AS id, drink.name AS name, drinktype.name as type FROM drink,drinktype WHERE drink.drinktype=drinktype.id AND (1=1) AND 1=1")
      q = "SELECT drink.id AS id, drink.name AS name, drinktype.name as type FROM drink,drinktype WHERE drink.drinktype=drinktype.id AND 1=0";
    q += " ORDER BY name";
    if(stringp(requestID->variables["startdrink"]))
      q += " LIMIT " + requestID->variables["startdrink"] + ",20";
    else
      q += " LIMIT 20";
    err = catch(a = db->query(q));
    if (err)
      error("Query failed: "+q+": "+err[0]);
    s += "<table width=\"100%\" rules=none border=0 align=center cellspacing=0 cellpadding=0 vspace=0 hspace=0>\n";
    s += "<tr>\n";
    s += TD_Small("", "hejsan");
    int to = (int)requestID->variables["startdrink"] + 20;
    if(sizeof(a) < to)
      to = sizeof(a);
    string s2 = sprintf("search result %d-%d of %d", (int)requestID->variables["startdrink"] + 1, to, sizeof(a));
    if((int)requestID->variables["startdrink"] != 0)
      s2 = "<< " + s2;
    if(to != sizeof(a))
      s2 += " >>";
    s += TD_Small("align=\"right\"", s2);
    s += "</tr>\n";
    s += "</table>\n";
    s += "<table width=\"100%\" rules=none frame=border border=1 align=center cellspacing=0 cellpadding=2 vspace=2 hspace=2>\n";
    for(int i = 0; i < sizeof(a); i++) {
      string name = roxen_encode(a[i]->name, "html");
      string id = roxen_encode(a[i]->id, "html");
      string type = roxen_encode(a[i]->type, "html");
      s += " <tr>\n"
           + TD_Normal("bgcolor=\"#006622\"", Button("?page=" + P_SHOWDRINK + "&id=" + id) + name)
           + TD_Normal("bgcolor=\"#007733\"", type) +
           " </tr>\n";
    }
    s += "</table>\n";
    s += q + "\n";*/
    newSearch = 0;
  }
  if(newSearch) {
    s += "Enter the name of the drink of ingredient and click 'Preform Search'.\n"
         "<br><br>\n"
         "<form method=\"post\" name=\"searchform\">\n"
         " <table border=\"0\" width=\"450\">\n"
         "  <tr>\n"
         + TD_Normal("", "Drink Name")
         + TD_Normal("", "<input type=\"text\" value=\"" + drinkname+ "\" name=\"drinkname\">") +
         "  </tr>\n"
         "  <tr></tr>\n"
         "  <tr>\n"
         + TD_Normal("", "Ingredients")
         + TD_Normal("", "<input type=\"text\" value=\"" + ingredients + "\" name=\"ingredients\">") +
         "  </tr>\n"
         " </table>\n"
         " <br>\n"
         " <i><font size=1 color=\"#99CC66\">You can use a simplified form of <a href=\"?page=" + P_SEARCHHELP + "\">advanced search syntax</a> in both fields.</font></i>\n"
         " <br><br>\n"
         + NiceSubmit("searchbutton", "Perform Search") +
         "</form>\n";
  }
  return s;
}

string
MainSearchPage()
{
  string s = "";
  s += H1("The Ultimate Drink Search") +
       H2("How to find the perfect drink") +
       H3("The importance of making the right choice") +
       "There are drinks for almost every occation. The problem is just figuring out\n"
       "which drink to drink and when to drink it. Luckily, the ultimate drink search\n"
       "offers an opportunity to find just that drink that you might have tried once\n"
       "but can't remember the name of. If you are in a situation where you want to\n"
       "make a tasty drink that contains a lot of alcohol and that consists partly of\n"
       "Bailey's (I'm sure you can think of a situation where that could be helpful)\n"
       "the ultimate drink search will help you out.\n"
       + H3("Finding the drinks") +
       "The ultimate drink search can be performed seaching for a drink\n"
       "with a certain name or ingredient or an advance search by listing certain\n"
       "attributes that the drink should have. When searching drinks by attributes\n"
       "all the drinks that match the chosen criteria will be listed.<br><br>\n"
       + Button("?page=" + P_NAMESEARCH) +
       "Search drinks by name and/or ingredientname<br>\n"
       + Button("?page=" + P_CRITERIASEARCH) +
       "Advanced search by criteria<br>\n"
       + H3("Finding an ingredient") +
       "Well, now you have found that drink you just HAVE to try.\n"
       "Then you just have to get a hold of all the ingredients and a whole\n"
       "new line of questions is spinning around in your head:\n"
       "What is Clam Juice? What is the difference between Whisky and Whiskey?\n"
       "What is the colour of Yellow Gatorade?<br>\n"
       "Find all the answers in the ultimate ingredient search!<br><br>\n"
       + Button("?page=" + P_INGREDIENTSEARCH) +
       "Search ingredients<br>\n"
       + H3("Contribute") +
       "For all helpful people out there who feel that they want to contribute, \n"
       "please send us your best drink recipes using by following this link.<br><br>\n"
       + Button("?page=" P_SENDDRINK) +
       "Guys, I think you have forgotten something!\n";
  return s;
}

string
GetPasswordPage()
{
  string s = "";
  string q = "";
  mixed err;
  array a;

  if(stringp(requestID->variables["sendbutton.x"])) {
    q = "SELECT name,email,password FROM submitter WHERE email='" + requestID->variables["email"] + "'";
    err = catch(a = db->query(q));
    if (err)
      error("Query failed: "+q+": "+err[0]);
    if(sizeof(a) == 1) {
      string name = roxen_encode(a[0]->name, "html");
      string email = roxen_encode(a[0]->email, "html");
      string password = roxen_encode(a[0]->password, "html");
      s += "<mailit>\n"
           " <mailheader subject=\"Password to Acats.org\">\n"
           " <mailheader to=\"" + a[0]->email + "\">\n"
           " <mailheader from=\"webmaster@acats.org\">\n"
           " <mailmessage encoding=7bit>\n"
           + name + ", your password to www.acats.org is '" + password + "'.\n"
           " </mailmessage>\n"
           "</mailit>\n"
           + H1("Password Sent") +
           "Your password have been sent to " + email + ". If you still can't log in, please contact the webmasters.\n";
    } else {
      s += H1("Not Registered") +
           "Your E-Mail address is not registered at Acats.org\n"
           + Bottom(Button("?page=" + P_REGISTER) + "Register to submit drinks");
    }
  } else {
    s += H1("Forgotten your password?") +
         "If you have forgotten your acats.org password, just type your E-Mail address in the field below and press the button. \n"
         "Your password  will then be sent to you via E-Mail.\n"
         "<form method=\"post\" name=\"getpassform\">\n"
         " <table>\n"
         "  <tr>\n"
         + TD_Normal("", "E-Mail")
         + TD_Normal("", "<input type=\"text\" size=30 maxsize=50 name=\"email\"></input>") +
         "  </tr>\n"
         " </table>\n"
         " <p>\n"
         + NiceSubmit("sendbutton", "Send Mail") +
         "</form>\n"
         "<script language=\"JavaScript\">\n"
         "document.getpassform.email.focus();\n"
         "</script>\n"
         + Bottom(Button("?page=" + P_REGISTER) + "Register to submit drinks");
  }
  return s;
}

string
ShowUserPage()
{
  string s = "";
  string q;
  array a;
  array b;
  mixed err;

  q = "SELECT * FROM submitter WHERE id=" + requestID->variables["id"];
  err = catch(a = db->query(q));
  if (err)
    error("Query failed: "+q+": "+err[0]);
  if(sizeof(a) == 1) {
    string publish = roxen_encode(a[0]->publish, "html");
    string name = roxen_encode(a[0]->name, "html");
    string info = roxen_encode(a[0]->info, "html");
    string homepage = roxen_encode(a[0]->homepage, "html");
    string country = roxen_encode(a[0]->country, "html");
    string email = roxen_encode(a[0]->email, "html");
    s += H1("View User") +
         H2(name) +
         "<table width=\"100%\" rules=none frame=border border=1 align=center cellspacing=0 cellpadding=4 vspace=4 hspace=4>\n"
         " <tr>\n"
         + TD_Normal("bgcolor=\"#006622\"", "About " + name)
         + TD_Normal("bgcolor=\"#007733\"", info) +
         " </tr>\n"
         " <tr>\n"
         + TD_Normal("bgcolor=\"#006622\"", "Homepage");
    if(homepage == "")
      s += TD_Normal("bgcolor=\"#007733\"", "");
    else if(a[0]->homepage[..6] == "http://")
      s += TD_Normal("bgcolor=\"#007733\"", homepage);
    else
      s += TD_Normal("bgcolor=\"#007733\"", "http://" + homepage);
    s += " </tr>\n"
         " <tr>\n"
         + TD_Normal("bgcolor=\"#006622\"", "Country of origin")
         + TD_Normal("bgcolor=\"#007733\"", country) +
         " </tr>\n"
         " <tr>\n"
         + TD_Normal("bgcolor=\"#006622\"", "Contact " + name);
    if(publish == "1")
      s += TD_Normal("bgcolor=\"#007733\"", replace(email, "@", "(at)"));
    else
      s += TD_Normal("bgcolor=\"#007733\"", "E-Mail Not Published");
    s += " </tr>\n"
         "</table>\n"
         "<p><br><br>\n"
         "<hr width=\"50%\">\n"
         "<p><br><br>\n"
         + name + " has submitted the following drinks to Acats.org<br>\n"
         "<table>\n"
         " <tr>\n";
    q = "SELECT name, id FROM drink WHERE submitter=" + requestID->variables["id"] + " ORDER BY name";
    catch(b = db->query(q));
    err = catch(b = db->query(q));
    if(err)
      error("Query failed: "+q+": "+err[0]);
    for(int i = 0; i < sizeof(b); i++) {
      string drinkname = roxen_encode(b[i]->name, "html");
      string drinkid = roxen_encode(b[i]->id, "html");
      if((i != 0) && (i % 2 == 0)) {
        s += " </tr>\n"
             " <tr>\n";
      }
      s += "  <td width=\"50%\">\n"
           "   <a href=\"?page=" + P_SHOWDRINK + "&id=" + drinkid + "\"><font size=2>" + drinkname + "</font></a>\n"
           "  </td>\n";
    }
    s += " </tr>\n"
         "</table>\n";
  }
  return s;
}

string
ShowIngredientPage()
{
  string s = "";
  string q;
  array a;
  array b;
  mixed err;

  q = "SELECT imagefilename, alcohole, ingredient.name AS name, description, history, ingredienttype.name AS type FROM ingredient,ingredienttype WHERE ingredient.type=ingredienttype.id AND ingredient.id=" + requestID->variables["id"];
  err = catch(a = db->query(q));
  if (err)
    error("Query failed: "+q+": "+err[0]);
  if(sizeof(a) == 1) {
    string name = roxen_encode(a[0]->name, "html");
    string type = roxen_encode(a[0]->type, "html");
    string imagefilename= roxen_encode(a[0]->imagefilename, "html");
    string alcohole = roxen_encode(a[0]->alcohole, "html");
    string description = roxen_encode(a[0]->description, "html");
    string history = roxen_encode(a[0]->history, "html");
    s += H1("The Ultimate Drink Search") +
         H2(name) +
         "Ingredient type : " + type + "<br>\n"
         "Alcohole : " + alcohole + "% " + sprintf("(%d-proof)",(int)(2*(float)alcohole)) + "<br>\n"
         "<br>\n"
         + description +
         "<br>\n"
         "<br>\n"
         "<hr>\n";
    if(imagefilename != "")
      s += "<center><img border=0 alt=\"IngredientImage\" src=\"/img/ingredients/" + imagefilename + "\"></center>";
    s += history +
         "<HR>\n"
         + H2("Drinks using " + name) +
         "<table>\n"
         " <tr>\n";
    q = "SELECT drink.name as name, drink.id as id FROM drink, drinkingredient WHERE drinkingredient.drink=drink.id AND drinkingredient.ingredient=" + requestID->variables["id"] + " ORDER BY name";
    catch(b = db->query(q));
    err = catch(b = db->query(q));
    if(err)
      error("Query failed: "+q+": "+err[0]);
    for(int i = 0; i < sizeof(b); i++) {
      string drinkname = roxen_encode(b[i]->name, "html");
      string drinkid = roxen_encode(b[i]->id, "html");
      if((i != 0) && (i % 2 == 0)) {
        s += " </tr>\n"
             " <tr>\n";
      }
      s += "  <td width=\"50%\">\n"
           "   <a href=\"?page=" + P_SHOWDRINK + "&id=" + drinkid + "\"><font size=2>" + drinkname + "</font></a>\n"
           "  </td>\n";
    }
    s += " </tr>\n"
         "</table>\n";
  }
  return s;
}

string
PreferencesPage()
{
  string s = "";
  string q = "";
  mixed err;
  array a;

  if(loginID != -1) {
    if(stringp(requestID->variables["updatebutton.x"])) {
      if(requestID->variables["password1"] == requestID->variables["password2"]) {
        string name = roxen_encode(requestID->variables["name"], "mysql");
        string email = roxen_encode(requestID->variables["email"], "mysql");
        string description = roxen_encode(requestID->variables["description"], "mysql");
        string homepage = roxen_encode(requestID->variables["homepage"], "mysql");
        string country = roxen_encode(requestID->variables["country"], "mysql");
        string password = roxen_encode(requestID->variables["password1"], "mysql");

        q = "UPDATE submitter SET name='" + name + "', email='" + email + "', password='" + password + "', "
            "homepage='" + homepage + "', ";
        if(stringp(requestID->variables["publish"])) {
          q += "publish=0, ";
        } else {
          q += "publish=1, ";
        }
        q += sprintf("country='" + country + "', info='" + description + "' where id=%d", loginID);
        err = catch(db->query(q));
        if (err)
          error("Query failed: "+q+": "+err[0]);
        s += "<remove_cookie name=acatspassword>\n"
             "<set_cookie name=acatspassword value='" + password + "' minutes=30>\n"
             + H1("Preferences updated") +
             "Your preferences have been updated.<br><hr>";
      } else {
       s += H1("Wrong Password") +
            "In order to change your password, you must type the same password in both boxes!";
      }
    }
    q = sprintf("SELECT * from submitter where id=%d", loginID);
    err = catch(a = db->query(q));
    if (err) {
      error("Query failed: "+q+": "+err[0]);
    } else {
      string name = roxen_encode(a[0]->name, "html");
      string email = roxen_encode(a[0]->email, "html");
      string description = roxen_encode(a[0]->info, "html");
      string homepage = roxen_encode(a[0]->homepage, "html");
      string country = roxen_encode(a[0]->country, "html");
      string publish = "";
      if(a[0]->publish == "0")
        publish = "checked";
      s += "To change your user data, just edit the form below and press the submit button.\n"
           "<p>\n"
           "<form method=\"post\" name=\"preferencesform\">\n"
           " <table width=\"100%\">\n"
           "  <input type=\"hidden\" name=\"email\" value=\"" + email + "\">\n"
           "  <tr>"
           + TD_Normal("width=\"30%\"", "Name")
           + TD_Normal("", "<input type=\"text\" size=30 maxsize=50 name=\"name\" value=\"" + name + "\">") + 
           "  </tr>\n"
           "  <tr>"
           + TD_Normal("width=\"30%\"", "New Password")
           + TD_Normal("", "<input type=\"password\" size=30 maxsize=50 name=\"password1\" value=\"" + requestID->cookies["acatspassword"] + "\">") + 
           "  </tr>\n"
           "  <tr>" 
           + TD_Normal("width=\"30%\"", "Retype Password")
           + TD_Normal("", "<input type=\"password\" size=30 maxsize=50 name=\"password2\" value=\"" + requestID->cookies["acatspassword"] + "\">") + 
           "  </tr>\n"
           "  <tr>" 
           + TD_Normal("width=\"30%\"", "Do not publish my E-Mail")
           + TD_Normal("", "<input type=\"checkbox\" name=\"publish\" " + publish + ">") + 
           "  </tr>\n"
           " </table>\n"
           " <hr>\n"
           " <table width=\"100%\">\n"
           "  <tr>"
           + TD_Normal("width=\"30%\"", "Homepage")
           + TD_Normal("", "<input type=\"text\" size=30 maxsize=100 name=\"homepage\" value=\"" + homepage + "\">") +
           "  </tr>\n"
           "  <tr>"
           + TD_Normal("width=\"30%\"", "Country")
           + TD_Normal("", "<input type=\"text\" size=30 maxsize=100 name=\"country\" value=\"" + country + "\">") +
           "  </tr>\n"
           "  <tr>"
           + TD_Normal("width=\"30%\"", "Description")
           + TD_Normal("", "<textarea rows=5 cols=25 name=\"description\">" + description + "</textarea>") +
           "  </tr>\n"
           " </table>\n"
           " <hr>\n"
           " <p>\n"
           + NiceSubmit("updatebutton", "Update") +
           "</form>\n"
           "<script language=\"JavaScript\">\n"
           "document.preferencesform.name.focus();\n"
           "</script>\n";
//             " <table width=\"100%\">\n"
//             "  <tr><tdnf width=\"50%\">When Listing Drink Ingredients</tdnf><tdnf align=right></tdnf><tdnf><select name=\"unit\">\n"
//             "   <option value=0 <if variable=\"unit is 0\">selected</if>>Do Not Convert</option>\n"
//             "   <option value=1 <if variable=\"unit is 1\">selected</if>>Convert To Metric System (cl)</option>\n"
//             "   <option value=2 <if variable=\"unit is 2\">selected</if>>Convert To Imperial(US) System (oz)</option>\n"
//             "   <option value=3 <if variable=\"unit is 3\">selected</if>>Convert To \"Bartender\" System (parts)</option>\n"
//             "  </select></tdnf></tr>\n"
//             " </table>\n"
    }
  } else {
    redirectTo = "?page=" + P_LOGIN;
  }
  return s;
}

string 
RegisterPage()
{
  string s = "";
  string password = "";
  string q;
  array a;

  if(stringp(requestID->variables["registerbutton.x"])) {
    for(int i = 0; i < 8; i++)
      password += sprintf("%c",'a' + random(26));
    q = "SELECT id FROM submitter WHERE email='" + requestID->variables["email"] + "'";
    mixed err = catch(a = db->query(q));
    if (err) {
      error("Query failed: "+q+": "+err[0]);
    } else if(sizeof(a)){
     s += H1("Already Registered") + 
          "You have already registered. If you have forgotten your password, please follow <a href=\"?page=" + P_GETPASSWORD + "\">this</a> link.";
    } else if(sizeof(requestID->variables["email"] / "@") > 1) { 
      s += "<mailit>\n"
           " <mailheader subject=\"Password to Acats.org\">\n"
           " <mailheader to=\"" + requestID->variables["email"] + "\">\n"
           " <mailheader from=\"Acats.org<webmaster@acats.org>\">\n"
           " <mailmessage encoding=7bit>\n"
           + requestID->variables["name"] + ", you have been registered on www.acats.org.\n"
           "Your login name is : " + requestID->variables["email"] + "\n"
           "Your password is : " + password + "\n"
           "You have choosen ";
      if(stringp(requestID->variables["publish"]))
        s += "not ";
      s += "to publish your E-Mail address.\n"
           "---------------------\n"
           "Homepage : " + requestID->variables["homepage"] + "\n"
           "Country: " + requestID->variables["country"] + "\n"
           "Description:\n"
           + requestID->variables["description"] + "\n"
           "---------------------\n"
           " </mailmessage>\n"
           "</mailit>\n"
           + H1("Registered") +
           "You have been registered. Your given password have been E-Mailed to you.\n";
//           "You have choosen to see the ingredient amount <if variable="unit is 0">as is</if><elseif variable="unit is 1">using metric system</elseif><elseif variable="unit is 2">using imperial system</elseif><else>using "bartender system"</else>.\n"
      // Insert into database here!
      q = "INSERT INTO submitter SET unit='" + requestID->variables["unit"] + "',name='" + roxen_encode(requestID->variables["name"], "mysql") + "',email='" + requestID->variables["email"] + "',homepage='" + roxen_encode(requestID->variables["homepage"], "mysql") + "',country='" + roxen_encode(requestID->variables["country"], "mysql") + "',password='" + password + "',info='" + roxen_encode(requestID->variables["description"], "mysql") + "',publish=";
      if(stringp(requestID->variables["publish"])) {
        q += "0";
      } else {
        q += "1";
      }
      array b;
      err = catch(b = db->query(q));
      if (err) {
        error("Query failed: "+q+": "+err[0]);
      }       
    } else {
     s += H1("Wrong E-Mail") +
          "You have not entered a valid E-Mail address. You need to provide us with your E-Mail in order to get your password sent to you.";
    }
  } else {
    s += H1("Registration") + 
         "So you have choosen to register your name and E-Mail in order to be able to send us drinks? Good choice!\n"
         "Please fill out the form below and then press the 'Register' button. Note that the only required\n"
         "fields are E-Mail and Name. E-Mail is required because a password will be automatically generated and sent\n"
         "to the E-Mail address that was provided in the registration. Please see our <a href=\"policy.html\" target=\"_blank\">privacy policy</a>.\n"
         "<p>\n"
         "An E-Mail will be sent to you containing your given password, which you can change at any time.\n"
         "When you have received the E-Mail just log in and send us your best drink recipes.<br>\n"
         "In order for people to know more about the you, feel free to write things about yourself in the description boxes.\n"
         "<p>\n"
         "Don't forget to check the checkbox if you do not want us to publish your E-Mail address.\n"
         "<form method=\"post\" autocomplete=\"off\" name=\"registerform\">\n"
         " <table width=\"100%\">\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "Name") + TD_Normal("align=right", "*") + TD_Normal("", "<input type=\"text\" size=30 maxsize=50 name=\"name\" autocomplete=\"OFF\"></input>") + "</tr>\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "E-Mail") + TD_Normal("align=right", "*") + TD_Normal("", "<input type=\"text\" size=30 maxsize=50 name=\"email\" autocomplete=\"OFF\"></input>") + "</tr>\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "Do not publish my E-Mail") + TD_Normal("", "") + TD_Normal("", "<input type=\"checkbox\" name=\"publish\" checked autocomplete=\"OFF\"></input>") + "</tr>\n"
         " </table>\n"
         " <hr>\n"
         " <table width=\"100%\">\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "Homepage") + TD_Normal("align=right", "") + TD_Normal("", "<input type=\"text\" size=30 maxsize=100 name=\"homepage\" autocomplete=\"OFF\"></input>") + "</tr>\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "Country") + TD_Normal("align=right", "") + TD_Normal("",  "<input type=\"text\" size=30 maxsize=100 name=\"country\" autocomplete=\"OFF\"></input>") + "</tr>\n"
         "  <tr>" + TD_Normal("width=\"50%\"", "Description") + TD_Normal("align=right", "") + TD_Normal("",  "<textarea rows=5 cols=25 name=\"description\" autocomplete=\"OFF\"></textarea>") + "</tr>\n"
         " </table>\n"
         " <hr>\n"
         " <p>\n"
         + NiceSubmit("registerbutton", "Register") + "\n"
         "</form>\n"
         "<script language=\"JavaScript\">\n"
         "document.registerform.name.focus();\n"
         "</script>\n";
//         " <table width=\"100%\">\n"
//         "  <tr>" + TD_Normal("width=\"50%\"", "When Listing Drink Ingredients") + TD_Normal("align=right", "") +
//         TD_Normal("", "<select name=\"unit\"><option value=0>Do Not Convert</option><option value=1>Convert To Metric System (cl)</option><option value=2>Convert To Imperial(US) System (oz)</option><option value=3>Convert To \"Bartender\" System (parts)</option></select>") +
//         "  </tr>\n"
//         " </table>\n"
  }
  return s;
}

string
ShowDrinkPage()
{
  string s = "";
  array a;
  array b;
  int i;
  float cAlcohole = 0;
  float cSize = 0;
  float fillPercentage = 0;
  int fills = 0;
  array(string) months = ({"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" });
  string q = "SELECT drink.id AS id, drink.name AS name, drink.history AS history, drink.creator AS creator, drink.drinkofyear AS drinkofyear, drink.drinkofmonth AS drinkofmonth, drink.grade AS grade, drink.country AS country, submitter.name as submitter, submitter.id AS submitterid, glass.name AS glass, glass.size AS glass_size, drinktype.name AS type, drink.numberofglasses as numberofglasses FROM drink,glass,drinktype,submitter "
             "WHERE drink.id=" + requestID->variables["id"] + " AND drink.glass=glass.id AND drink.drinktype=drinktype.id AND drink.submitter=submitter.id";
  mixed err = catch(a = db->query(q));
  if (err) {
    error("Query failed: "+q+": "+err[0]);
  } else if(sizeof(a)){
    string name = roxen_encode(a[0]->name, "html");
    string history = roxen_encode(a[0]->history, "html");
    string creator = roxen_encode(a[0]->creator, "html");
    string drinkofmonth = roxen_encode(a[0]->drinkofmonth, "html");
    string drinkofyear = roxen_encode(a[0]->drinkofyear, "html");
    string grade = roxen_encode(a[0]->grade, "html");
    string creator = roxen_encode(a[0]->creator, "html");
    string country = roxen_encode(a[0]->country, "html");
    string submitter = roxen_encode(a[0]->submitter, "html");
    string submitterid = roxen_encode(a[0]->submitterid, "html");
    string glass = roxen_encode(a[0]->glass, "html");
    string glass_size = roxen_encode(a[0]->glass_size, "html");
    string type = roxen_encode(a[0]->type, "html");
    string numberofglasses = roxen_encode(a[0]->numberofglasses, "html");
    s += H1("The Ultimate Drink Search") +
         H2(name) +
         "Drinktype : " + type + "<br>\n"
         "Served in : " + glass + "Glass<br>\n"
         "Number of glasses : " + numberofglasses + "<br>\n"
         "<P>";
    q = "SELECT ingredient.id AS ingredientid, ingredient.alcohole AS alcohole, drinkingredient.amount AS amount, unit.abbrevation AS unit, unit.centiliters AS centiliters, ingredient.name AS name, ingredient.alcohole*drinkingredient.amount*unit.centiliters AS alc FROM unit,drinkingredient,ingredient "
        "WHERE drinkingredient.drink=" + requestID->variables["id"] + " AND drinkingredient.ingredient=ingredient.id AND unit.id = drinkingredient.unit ORDER BY alc DESC,centiliters DESC";
    err = catch(b = db->query(q));
    if (err)
      error("Query failed: "+q+": "+err[0]);
    for(i = 0; i < sizeof(b); i++) {
      string unit = roxen_encode(b[i]->unit, "html");
      string ingredientid = roxen_encode(b[i]->ingredientid, "html");
      string ingredientname = roxen_encode(b[i]->name, "html");
      string amount = roxen_encode(b[i]->amount, "html");
      string unit = roxen_encode(b[i]->unit, "html");
      string centiliters = roxen_encode(b[i]->centiliters, "html");
      string alcohole = roxen_encode(b[i]->alcohole, "html");
      if(unit == "fill") {
        s += "Fill up with <a href=\"?page=" + P_SHOWINGREDIENT + "&id=" + ingredientid + "\">" + ingredientname + "</a><br>\n";
      } else {
        s += amount + " " + unit + " of <a href=\"?page=" + P_SHOWINGREDIENT + "&id=" + ingredientid + "\">" + ingredientname + "</a><br>\n";
      }
      float cl, am, al;
      cl = (float)centiliters;
      am = (float)amount;
      al = (float)alcohole;
      if(cl > 0) {
        cAlcohole += am * cl * al / 100;
        cSize += am * cl;
      }
      if(unit == "fill") {
        fills++;
        fillPercentage += al / 100;
      }
    }
    if(fills > 0) {
      cAlcohole += ((float)glass_size - cSize) * (fillPercentage / fills);
      cSize = (float)glass_size;
    }
    //s += sprintf("alcohol : %f, size : %f, perc : %.2f", cAlcohole, cSize, 100*cAlcohole/cSize);
    s += sprintf("<BR>This drink contains approximately %.2f%% alcohol.<br>(Equals %.2f cl 80-proof alcohol.)", 100*cAlcohole/cSize, cAlcohole*2.5) +
         "<BR><BR>\n"
         "<HR>\n"
         + H3("Origin");
    if(creator == "Unknown") {
      s += "Nothing is known about the creator of " + name + ".\n";
    } else {
      s += name + " was invented by " + creator + ".\n";
    }
    s += "It has been provided to the Aristocats drink database by <a href=\"?page=" + P_SHOWUSER + "&id=" + submitterid + "\">" + submitter + "</a>."
         "<br>";
    if(stringp(history) && history != "") {
      s += H3("History") +
           history;
    }
    s += "<BR><BR>\n"
         "<HR>\n"
         + H3("Information you did not ask for");
    if(drinkofmonth != "0") {
      s += name + " was drink of the month in " + months[(int)drinkofmonth - 1] + " " + drinkofyear + ".<Br><BR>\n";
    } else {
      s += name + " has never been drink of the month.<BR><BR>\n";
    }
    if(grade != "0") {
      s += "This drink has been tested by Aristocats bar crew.<BR>\n";
      if(grade == "1") {
        s += "The grade given was " + grade + " shaker out of 10 possible.<BR><BR>\n";
      } else {
        s += "The grade given was " + grade + " shakers out of 10 possible.<BR><BR>\n";
      }
    }
    if(country != "") {
      s += "This drink originates from " + country + ".<BR><BR>\n";
    }
    s += "<font size=1><a href=\"showdrink_printable.html?id=" + requestID->variables["id"] + "\">Click here for a print friendly page</a></font>";

  }
  return s;
}

string LogoutPage()
{
  if(loginID != -1) {
    return "<remove_cookie name=acatsemail>\n"
           "<remove_cookie name=acatspassword>\n"
           "<redirect to=\"?page=" + P_LOGOUT + "\">\n";
  } else {
    return H1("Logged out") +
           "You have been logged out.\n"
           "To log in again, click on Login.\n";
  }
}

string
LoginPage()
{
  string s = "";
  if(loginID != -1) {
    if(requestID->variables["origin"]) {
      if(sizeof(requestID->variables["origin"] / ("page=" + P_LOGIN)) > 1) {
        redirectTo = "http://www.acats.org";
      } else if(sizeof(requestID->variables["origin"] / ("page=" + P_LOGOUT)) > 1) {
        redirectTo = "http://www.acats.org";
      } else {
        redirectTo = requestID->variables["origin"];
      }
    } else {
      redirectTo = "http://www.acats.org";
    }
  } else {
    if(stringp(requestID->variables["loginbutton.x"])) {
      s += H1("Login Failed");
    } else {
      s += H1("Who Are You?");
    }
    s += "In order to send a drink to us and have own settings, you have to provide us with your name, your E-Mail address and if you would like to a text describing yourself.\n"
         "If you have not done that, you can do it by following the link at the bottom left of the page.<br>\n"
         "If you want to send us drinks without register, i.e. anonymous, please send us you recipe in an E-Mail.\n"
         "<p>\n"
         "If you have already registered, please login using your E-Mail address and your given password.\n"
         "<p>\n"
         "If you have do not remember your password, please follow <a href=\"?page=" + P_GETPASSWORD + "\">this</a> link to get it sent to you.\n"
         "<form method=\"post\" autocomplete=\"off\" name=\"loginform\">\n"
         " <table>\n"
         "  <tr><tdnf>E-Mail</tdnf><tdnf><input type=\"text\" size=30 maxsize=50 name=\"email\"></input></tdnf></tr>\n"
         "  <tr><tdnf>Password</tdnf><tdnf><input type=\"password\" size=30 maxsize=50 name=\"password\"></input></tdnf></tr>\n"
         "  <input type=hidden name=origin value=\"<referrer>\">\n"
         " </table>\n"
         " <p>\n"
         + NiceSubmit("loginbutton", "Login") +
         "</form>\n"
         "<script language=\"JavaScript\">\n"
         " document.loginform.email.focus();\n"
         "</script>\n";
  }
  return s;
}

string
StartPage()
{
  array a;
  string id = "-1";
  string name = "";
  string date = "";
  string submitted = "";
  string history = "";
  string q = "select id,name,history from drink where drinkofyear=year(curdate()) and drinkofmonth=month(curdate())";
  mixed err = catch(a = db->query(q));
  if (err) {
    error("Query failed: "+q+": "+err[0]);
  } else if(sizeof(a)){
		id = roxen_encode(a[0]->id, "html");
		name = roxen_encode(a[0]->name, "html");
		history = roxen_encode(a[0]->history, "html");
  }

  string s = H1("Acats Internet Bar Pages") + "\n"
             + H2("Welcome") + "\n"
             "The purpose of Acats Internet Bar Pages is to educate those who want\n"
             "to learn about the noble art of bartending. These pages contains\n"
             "anything from delicious cocktails to building the bar and the best\n"
             "pickuplines for your night out. From all of the Acats \"We wish you\n"
             "a very pleasant reading. Enjoy!\"\n"
             "<p>\n"
             "We also want to thank Jessica Hammerin for the help with the\n"
             "design of our new pages.\n"
             "<br><br><br>\n";
  if(id != "-1") {
    s +=     H2("Drink of the month") + "\n"
             "<a href=\"?page=" + P_SHOWDRINK + "&id=" + id + "\"><center><b>" + name + "</b></center></a>\n"
             "<br>\n"
             "<table><tr>" + TD_Normal("width=\"0%\"", "") + TD_Normal("", "\"" + history + "\"") + "</tr></table>\n"
             + Right("- Aristocats") + "\n"
             "<br>\n";
  }

  s += H2("Drinks added the last week");
  int i;
  for(i = 0; i < 7; i++) {
    int first = 0;
    string q = sprintf("select drink.id as id,drink.name as name,submitter.id as subid,submitter.name as submitted,date_format(drink.date,'%%M %%D, %%Y') as date from drink,submitter where drink.date=curdate() - interval %d day and drink.submitter=submitter.id", i);
    int j;
    catch(a = db->query(q));
    for(j = 0; j < sizeof(a); j++) {
      id = roxen_encode(a[j]->id, "html");
      name = roxen_encode(a[j]->name, "html");
      date = roxen_encode(a[j]->date, "html");
      submitted = roxen_encode(a[j]->submitted, "html");
      if(first == 0)
        s += "<b>" + date + "</b><br>\n";
      s += "<a href=\"?page=" + P_SHOWDRINK + "&id=" + id + "\">" + name + "</a>, submitted by " + submitted + "<br>\n";
      first = 1;
    }
  }
  return s;
}

string
GetLoginInfo()
{
  array a;
  string email = "";
  string password = "";
  string s = "";

  if(stringp(requestID->cookies["acatsemail"])) {
    email = requestID->cookies["acatsemail"];
    password = requestID->cookies["acatspassword"];
  }
  if(stringp(requestID->variables["password"])) {
    email = requestID->variables["email"];
    password = requestID->variables["password"];
  }
  string q = "select id,name,email,password from submitter where email='" + email + " ' and password='" + password + "'";
  loginID = -1;
  loginName = "";
  mixed err = catch(a = db->query(q));
  //s += email + "/" + password;
  if (err) {

    error("Query failed: "+q+": "+err[0]);
    return s;
  }
  if(sizeof(a)) {
    loginID = (int)roxen_encode(a[0]->id, "html");
    loginName = roxen_encode(a[0]->name, "html");
    q = sprintf("update submitter set lastlogin=curdate() where id=%d", loginID);
    catch(a = db->query(q));
    s += "<remove_cookie name=acatsemail>\n"
         "<remove_cookie name=acatspassword>\n"
         "<set_cookie name=acatsemail value='" + email + "' minutes=30>\n"
         "<set_cookie name=acatspassword value='" + password + "' minutes=30>\n";
  }
  return s;
}

string
H1(string txt)
{
 return "<p><font size=6 face=\"Century Gothic, Arial, Helvetica\" color=\"#99CC66\">" + txt + "</font><p>&nbsp;<p>\n";
}

string
H2(string txt)
{
 return "<p><font size=4 face=\"Century sGothic, Arial, Helvetica\" color=\"#99CC66\">" + txt + "</font></p>\n";
}

string
H3(string txt)
{
 return "<p><font size=2 face=\"Century Gothic, Arial, Helvetica\" color=\"#99CC66\">" + txt + "</font></p>\n";
}

string
TD_Normal(string args, string txt)
{
 return "<td " + args + "><font face=\"Century Gothic, Arial, Helvetica\" size=\"2\" color=\"#FFFFFF\">" + txt + "</font></td>\n";
}

string
TD_Small(string args, string txt)
{
 return "<td " + args + "><font face=\"Century Gothic, Arial, Helvetica\" size=\"1\" color=\"#FFFFFF\">" + txt + "</font></td>\n";
}

string
TH_Normal(string args, string txt)
{
  return "<th " + args + "><font face=\"Century Gothic, Arial, Helvetica\" size=\"2\" color=\"#FFFFFF\">" + txt + "</font></th>\n";
}

string
TH_Small(string args, string txt)
{
  return "<th " + args + "><font face=\"Century Gothic, Arial, Helvetica\" size=\"1\" color=\"#FFFFFF\">" + txt + "</font></th>\n";
}

string
Right(string txt)
{
  return "<br clear=all><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" vspace=\"0\" hspace=\"0\"><tr><td align=\"right\" valign=\"bottom\" Height=\"20\"><font face=\"Century Gothic, Arial, Helvetica\" size=\"2\">" + txt + "</font></td></tr></table>\n";
}

string
Bottom(string txt)
{
  return "<br clear=all><table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" vspace=\"0\" hspace=\"0\"><tr><td align=\"right\" valign=\"bottom\" Height=\"50\"><font face=\"Century Gothic, Arial, Helvetica\" size=\"2\">" + txt + "</font></td></tr></table>\n";
}

string
NiceSubmit(string name, string txt)
{
  return "<input type=\"image\" name=\"" + name + "\" <gtext fg=lightgreen spacing=2 border=2,lightgreen scale=0.4 bevel=1 fs>" + txt + "</gtext>\n";
}

string
Button(string href)
{
  return "<a href=\"" + href + "\"><img src=\"/img/knapp.gif\" width=\"25\" height=\"28\" align=\"absmiddle\" border=\"0\" vspace=\"0\" hspace=\"0\"></a>\n";
}

string
Swedish(string href)
{
  return "<a href=\"" + href + "\"><img src=\"/img/swedish.gif\" width=\"35\" height=\"24\" align=\"absmiddle\" border=\"0\" vspace=\"0\" hspace=\"0\"></a>&nbsp;&nbsp;\n";
}

string
CreateHeader()
{
  string s = "";
  s += "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n" 
       "<html>\n"
       " <head><sb-output file>\n"
       "   <meta name=\"keywords\" content=\"#keywords#\">\n"
       "   <meta name=\"description\" content=\"#description#\">\n"
       "   <title>#title#</title></sb-output>\n"
       " </head>\n"
       " <body bgcolor=\"#006633\" text=\"#FFFFFF\" link=\"#99CC66\" vlink=\"#99CC99\" alink=\"#009966\">\n"
       "  <table border=\"0\" width=\"700\" cellspacing=\"0\" cellpadding=\"0\">\n"
       "   <tr> \n"
       "    <td width=\"275\" align=\"left\" valign=\"top\">\n"
       "     <img src=\"/img/acatsmeny.gif\" width=\"275\" height=\"550\" border=\"0\" vspace=\"0\" hspace=\"0\" usemap=\"#meny\" align=\"top\" alt=\"menu\">\n"
       "     <table rules=none frame=border border=1 align=center cellspacing=0 cellpadding=2>\n"
       "      <thead>\n"
       "       <tr bgcolor=\"#004400\">\n"
       "        <th align=center>\n"
       "         <font face=\"Century Gothic, Arial, Helvetica\" size=\"1\" color=\"#99CC66\">\n";
  if(loginID != -1)
    s += loginName + " logged in\n";
  else
    s += "not logged in\n";
  s += "         </font>\n"
       "        </th>\n"
       "       </tr>\n"
       "      </thead>\n"
       "      <tr>\n"
       "       <td align=center>\n"
       "        <font face=\"Century Gothic, Arial, Helvetica\" size=\"1\" color=\"#99CC66\">\n";
  if(loginID != -1)
    s += "         <a href=\"?page=" + P_PREFERENCES + "\">Preferences</a>\n";
  else
    s += "         <a href=\"?page=" + P_REGISTER + "\">Register</a>\n";
  s += "        </font>\n"
       "       </td>\n"
       "      </tr>\n"
       "      <tr>\n"
       "       <td align=center>\n"
       "        <font face=\"Century Gothic, Arial, Helvetica\" size=\"1\" color=\"#99CC66\">\n";
  if(loginID != -1)
    s += "         <a href=\"?page=" + P_LOGOUT + "\">Logout</a>\n";
  else
    s += "         <a href=\"?page=" + P_LOGIN + "\">Login</a>\n";
  s += "        </font>\n"
       "       </td>\n"
       "      </tr>\n"
       "     </table>\n"
       "    </td>\n"
       "    <td width=\"425\" valign=\"top\">\n"
       "     <table border=\"0\" width=\"425\" cellspacing=\"0\" cellpadding=\"0\">\n"
       "      <tr>\n"
       "       <td align=\"left\" valign=\"top\" height=\"52\">&nbsp;</td>\n"
       "      </tr>\n"
       "      <tr>\n"
       "       <td>\n"
       "       <font face=\"Century Gothic, Arial, Helvetica\" size=\"2\">\n";
  return s;
}

string
CreateFooter()
{
  return "        </font>\n"
         "       </td>\n"
         "      </tr>\n"
         "      <tr>\n"
         "       <td align=\"right\" valign=\"bottom\" height=\"100\">\n"
         "        <font face=\"Century Gothic, Arial, Helvetica\" size=\"1\">\n"
         "         &copy; 2002 Acats. If you have any questions or comments, email the <a href=\"mailto:webmaster@acats.org\">Webmasters</a>.\n"
         "        </font>\n"
         "       </td>\n"
         "      </tr>\n"
         "      <tr>\n"
         "       <td align=\"right\" valign=\"bottom\" height=\"44\">&nbsp;</td>\n"
         "      </tr>\n"
         "     </table>\n"
         "    </td>\n"
         "   </tr>\n"
         "  </table>\n"
         "  <map name=\"meny\">\n"
         "   <area shape=\"rect\" coords=\"170,191,224,246\" href=\"/drinkedit/listdrinks.html\" alt=\"Do NOT Click Here\">\n"
         "   <area shape=\"rect\" coords=\"43,191,97,246\" href=\"/drinklist/introduction.html\" alt=\"Various Drinklists\">\n"
         "   <area shape=\"rect\" coords=\"106,127,161,180\" href=\"/drinkdatabase/introduction.htm\" alt=\"Search the Database\">\n"
         "   <area shape=\"rect\" coords=\"106,381,162,431\" href=\"/links.html\" alt=\"Links\">\n"
         "   <area shape=\"rect\" coords=\"170,319,224,372\" href=\"/about/whatabout.html\" alt=\"About Acats\">\n"
         "   <area shape=\"rect\" coords=\"106,255,161,310\" href=\"/entertainment/entertainment.html\" alt=\"To Entertain\">\n"
         "   <area shape=\"rect\" coords=\"43,255,97,310\" href=\"/bartending/bartending.html\" alt=\"Bartending Guide\">\n"
         "   <area shape=\"rect\" coords=\"51,45,228,114\" href=\"/index.html\" alt=\"To Start Page\">\n"
         "  </map> \n"
         " </body>\n"
         "</html>\n";
}

mapping|object
parse(object id)
{

  mixed err;
  string str = "";

  requestID = id;
  redirectTo = "";

  // Connect to database
  err = catch(db = Sql.sql(SQL_DATABASE));
  if(err) {
    string s = "Cannot connect to SQL database: " + err[0];
    error(s);
    return http_string_answer(s);
  }

  str += GetLoginInfo();

  switch(requestID->variables["page"]) {
    case P_LOGIN:
      str += LoginPage();
      break;
    case P_LOGOUT:
      str += LogoutPage();
      break;
    case P_SHOWDRINK:
      str += ShowDrinkPage();
      break;
    case P_REGISTER:
      str += RegisterPage();
      break;
    case P_PREFERENCES:
      str += PreferencesPage();
      break;
    case P_SHOWINGREDIENT:
      str += ShowIngredientPage();
      break;
    case P_SHOWUSER:
      str += ShowUserPage();
      break;
    case P_GETPASSWORD:
      str += GetPasswordPage();
      break;
    case P_MAINSEARCH:
      str += MainSearchPage();
      break;
    case P_NAMESEARCH:
      str += NameSearchPage();
      break;
    default:
      //DEBUG!!!
      str += NameSearchPage();
//      str += StartPage();
  }

  if(redirectTo != "")
    return http_rxml_answer(CreateHeader() + str + "<redirect to=\"" + redirectTo + "\">\n" + CreateFooter(), id);
  else
    return http_rxml_answer(CreateHeader() + str + CreateFooter(), id);

  //return http_redirect(redirectTo, requestID);
}
