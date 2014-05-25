pub enum Cmd {
  Pass(~str),
  Ping(~str),
  Pong(~str),
  Join(~str),
  Quit(~str),
  Nick(~str),
  User(~str, ~str, ~str, ~str),
  Privmsg(~str, ~str, ~str),
}

impl Cmd {
  pub fn token(&self) -> &'static str {
    match *self {
      Pass(..)    => "PASS",
      Ping(..)    => "PING",
      Pong(..)    => "PONG",
      Join(..)    => "JOIN",
      Quit(..)    => "QUIT",
      Nick(..)    => "NICK",
      User(..)    => "USER",
      Privmsg(..) => "PRIVMSG",
    }
  }

   pub fn out_msg(&self) -> ~str {
    self.token() + " " + 
      match *self {
        Pass(ref arg) | Nick(ref arg) | Ping(ref arg) | Pong(ref arg) | Join(ref arg) | Quit(ref arg) => {
          arg.to_owned()
        },
        User(ref nick, ref hostname, ref servername, ref realname) => {
          format!("{:s} {:s} {:s} :{:s}", *nick, *hostname, *servername, *realname)
        },
        Privmsg(_, ref receiver, ref msg) => {
          format!("{:s} :{:s}", *receiver, *msg)
        }
      }
  }
}

pub fn parse_cmd(msg: ~str) -> Option<Cmd> {
  let token_list :~[&str] = msg.trim_chars(& &['\r', '\n']).words().collect();
  let token_count = token_list.len();

  if token_count < 2 {
    fail!("not enough parameter in cmd");
  }

  if token_list[0].starts_with(":") {    
    match token_list[1] {
      "PRIVMSG" => {
        if token_count > 3 {
          // TODO: optimize this mess
          let from = token_list[0].slice(1, token_list[0].find_str("!").unwrap()).to_owned();
          let to = token_list[2].to_owned();
          let content = token_list.slice_from(3).connect(" ").slice_from(1).to_owned();

          Some(Privmsg(from, to, content))
        } else {
          None
        }
      },
      _ => None
    }
  } else {
    match token_list[0] {
      "PING" => Some(Ping(token_list[1].to_owned())),
      _ => None
    }
  }
}