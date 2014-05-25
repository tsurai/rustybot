#![feature(phase)]

#[phase(syntax,link)]
extern crate lua;

use bot::Bot;

mod bot;
mod cmd;

fn main() {
  let mut bot = Bot::new(~"irc.rizon.net", 6667, ~"shikinami", ~"#tsukiro");
  bot.run();
}