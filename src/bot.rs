use lua;

use std::cast;
use std::vec::Vec;
use std::libc::c_void;
use std::io::BufferedStream;
use std::io::net::addrinfo;
use std::io::net::tcp::TcpStream;
use std::io::net::ip::{SocketAddr};

use cmd;

pub static VERSION: &'static str = "0.3-alpha";

pub struct Bot {
  hostname:     ~str,
  port:         u16,
  nick:         ~str,
  channel:      ~str,
  stream:       Option<BufferedStream<TcpStream>>,
  lua:          lua::State,
  lua_manager:  i32,
}

impl Bot {
  pub fn new(hostname: ~str, port: u16, nick: ~str, channel: ~str) -> Bot {
    let mut l = lua::State::new();
    l.openlibs();

    return Bot{ hostname: hostname, port: port, nick: nick, channel: channel, stream: None, lua: l, lua_manager: -1 };
  }

  fn load_config(&mut self) {

  }

  fn connect(&mut self) {
    match addrinfo::get_host_addresses(self.hostname) {
      Ok(addr_info) => {
        for addr in addr_info.iter() {
          let sock = ~TcpStream::connect(SocketAddr{ ip: *addr, port: self.port });

          if sock.is_ok() {
            self.stream = Some(BufferedStream::new(sock.unwrap()));
            return;
          }
        }
      },
      Err(err) => {
        fail!("Error: {}", err);
      }
    }

    fail!("Error: can't resolve hostname");
  }

  fn login(&mut self) {
    let nick = self.nick.clone();
    let channel = self.channel.clone();

    self.send(~cmd::Pass(~"supersecret"));
    self.send(~cmd::Nick(nick.clone()));
    self.send(~cmd::User(nick.clone(), ~"host", ~"server", ~"real name"));
    self.send(~cmd::Join(channel));
  }

  fn send(&mut self, cmd: ~cmd::Cmd) {
    let out_stream = self.stream.get_mut_ref();

    match out_stream.write_line(format!("{}", cmd.out_msg())) {
      Ok(_) => {},
      Err(err) => fail!("Error: {}", err),
    }

    match out_stream.flush() {
      Ok(_) => {},
      Err(err) => fail!("Error: {}", err),
    }

    println!("C> {}", cmd.out_msg());
  }

  pub fn run(&mut self) {
    let mut l = &self.lua;

    l.register("version", version_lua);
    l.pushlightuserdata(self as *mut _ as *mut c_void);
    l.pushcclosure(send_lua, 1);
    l.setglobal("send");

    match l.loadfile(Some(&Path::new("manager.lua"))) {
      Ok(_) => {
        match l.pcall(0, 1, 0) {
          Ok(_) => self.lua_manager = l.ref_(lua::REGISTRYINDEX),
          Err(err) => fail!("Error: {}. {}", err, l.describe(-1))
        }
      },
      Err(_) => {
        fail!("Error: {}", l.describe(-1));
      }
    }

    self.load_plugins();

    self.connect();
    self.login();

    loop {
      let out = self.stream.get_mut_ref().read_line().unwrap();
      print!("S> {}", out);

      match cmd::parse_cmd(out.clone()) {
        Some(cmd) => {
          match cmd {
            cmd::Ping(ref arg) => {
              self.send(~cmd::Pong(arg.to_owned()));
              continue
            },
            cmd::Privmsg(ref from, ref receiver, ref msg) => {
              if receiver.starts_with("#") {
                if msg.starts_with(self.nick + ": ") {
                  if from.clone() != ~"tsurai" {
                    continue
                  }
                  let input = msg.slice_from(self.nick.len() + 2);
                  l.rawgeti(lua::REGISTRYINDEX, self.lua_manager);
                  l.getfield(-1, "process_plugins");
                  l.pushstring(from.clone());
                  l.pushstring(receiver.clone());
                  l.pushstring(input);
                  match l.pcall(3, 0, 0) {
                    Ok(_) => (),
                    Err(err) => fail!("Error: {}. {}", err, l.describe(-1))
                  }
                }
              }
              continue
            },
            _ => continue
          }
        },
        None => {}
      }
    }
  }

  pub fn load_plugins(&self) {
    let mut l = &self.lua;
    let path = &Path::new("plugins");
    
    l.rawgeti(lua::REGISTRYINDEX, self.lua_manager);
    l.getfield(-1, "load_plugins");
    l.pushstring(format!("{}", path.display()));

    match l.pcall(1, 1, 0) {
      Ok(_) => {
       if !l.toboolean(-1) {
          fail!("Error: failed to load plugin {}", path.filename_display());
        } else {
          println!("Success");
        }
      },
      Err(err) => fail!("Error: {}. {}", err, l.describe(-1))
    }
  }
}

lua_extern! {
  unsafe fn send_lua(l: &mut lua::ExternState) -> i32 {
    let mut param = Vec::new();
    let mut index = 0;
    
    loop {
      index = index + 1;
      match l.type_(index) {
        Some(t) => if t != lua::Type::String { break; },
        None => break
      }
      param.push(l.tostring(index).unwrap())
    }

    if param.len() > 1 {
      let cmd = match param.get(0).clone() {
        "JOIN" => Some(~cmd::Join(param.get(1).to_owned())),
        "QUIT" => Some(~cmd::Quit(param.get(1).to_owned())),
        "NICK" => Some(~cmd::Nick(param.get(1).to_owned())),
        "PRIVMSG" => {
          if param.len() == 3 {
            Some(~cmd::Privmsg(~"", param.get(1).to_owned(), param.get(2).to_owned()))
          } else {
            None
          }
        },
        _ => None 
      };

      let bot: &mut Bot = cast::transmute(l.touserdata(lua::upvalueindex(1)));

      match cmd {
        Some(c) => bot.send(c),
        None => () 
      }

    }
    0
  }

  unsafe fn version_lua(l: &mut lua::ExternState) -> i32 {
    l.pushstring(VERSION);
    1
  }
}