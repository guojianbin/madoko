/*---------------------------------------------------------------------------
  Copyright 2013 Microsoft Corporation.
 
  This is free software; you can redistribute it and/or modify it under the
  terms of the Apache License, Version 2.0. A copy of the License can be
  found in the file "license.txt" at the root of this distribution.
---------------------------------------------------------------------------*/

// Formatting of  HTML elements 
module htmlFormatter

import std/dict
import std/string
import std/regex
import std/log
import std/path
import common
import inline
import options
import codeAlign
import attributes // expandKeys
import hilite

public function fmtHtmlEnv(context : inlineContext, env : string, txt : string, attrs : attrs ) : string {
  if (env=="") 
   then txt 
   else tagEnv(env.translate(attrs,context.sanitize), (if(env.length>3) then "\n" else "") + txt,attrs,context.sanitize)
}


public function fmtHtmlCmd(context : inlineContext, cmd : string, txt : string, attrs : attrs ) : string {
  if (cmd=="") then txt else tag(cmd.translate(attrs,context.sanitize),txt,attrs.htmlFormat(cmd,context.sanitize))
}

public function fmtHtmlLineInfo(context : inlineContext, lineInfo : string ) : string {
  "<span data-line=\"" + lineInfo + "\"></span>"
}


function translate(tagName : string, attrs : attrs, sanitize : bool ) : string  {
  if (attrs.empty || sanitize) return tagName
  if (attrs.htmlelem != "") 
   then attrs.htmlelem
   else tagName
}

public function fmtHtmlEscape(context : inlineContext, txt : string, allowEntity : bool ) : string {
  htmlEscape(txt,allowEntity)
}

public function fmtHtmlFootnote(context : inlineContext, id : string, fn : footnote ) : string {
  tag("sup", 
    tag("a", fn.footnoteNum, " href=\"#fn-" + escape(id) + "\" " +
          "title=\"" + fn.footnoteCaption.extractText.escape + "\" " +
          "class=\"footnote-ref localref\" " ),
          " id=\"back-fn-" + escape(id) + "\" " )
}

public function fmtHtmlTable( context : inlineContext, head : list<row>, body : list<row>, colattrs : list<attrs>, attrs : attrs  ) : string {
  tag("table", 
    context.fmtRows("thead","th",head) + context.fmtRows("tbody","td",body),
    attrs.addClass("block").htmlFormat("table",context.sanitize))
}

function fmtRows( context : inlineContext, tbody : string, td : string, rows : list<row> ) : string {
  if (rows.isNil) then return ""
  tagBlock(tbody,
    rows.map( fun(row) {
      tag("tr", row.cells.map(fun(cell) { 
                    val cattrs1 = match(cell.cellAttrs.hasKey("rule-width")) {
                                     Just(wd) -> cell.cellAttrs
                                                  .addKeyvalIfNotExist("border-top-width",wd)
                                                  .addKeyvalIfNotExist("border-bottom-width",wd)
                                     Nothing  -> cell.cellAttrs
                                   }
                    tag(td,cell.text, cattrs1.htmlFormat(td,context.sanitize)) 
                }).join, 
                //row.rowAttrs.htmlFormat("tr",context.sanitize)
                "") 
    }).join("\n"))
} 

public function fmtHtmlCodeTable( context : inlineContext, ct : codeTable, attrs : attrs ) : string {
  tag("table", tagBlock("tbody", context.fmtCtRows( ct.rows ) ), attrs.addClass("block").htmlFormat("table",context.sanitize) )
}

function fmtCtRows( context : inlineContext, rows : list<crow> ) : string {
  rows.map( fun(row) {
    tag("tr", row.mapIndexed( fun(i,cell) {
                val empty = cell.content.isAllWhite
                val expander = if (row.length==i+1) then " expander" else ""
                val classes = "colspan" + cell.span.show + expander + (if (empty) then " empty" else "")
                val attrs = " class='" + classes + "'" + (if (cell.span > 1) then " colspan='" + cell.span.show + "'" else "")
                tag("td", if (empty) then "&nbsp;" else cell.content, attrs )                
              }).join, "")
  }).join("\n")  
}

function isAllWhite( s : string ) : bool {
  s.contains(rxWhite)
}
val rxWhite = regex(@"^\s*$")

/*
function isHtmlWhite( s : string ) : bool {
  s.find(rxAllWhite).bool
}
val rxAllWhite = regex(@"^(\s|&nbsp;|<span\b[^>]*>(\s|&nbsp;)*</span>)*$")
*/

public function fmtHtmlLink( context : inlineContext, isImage : bool, link : link, content : string) {
  if (isImage) {
    val imgref = if (link.href.relative && link.href.extname == ".eps") then link.href.changeExt(".png") else link.href
          
    val href = match (context.embedinfos[imgref]) {
      Just(info) | info.embedData != "" -> {
        //trace("embedded: " + info.embedName)
        info.embedData 
      }
      _          -> {
        if (imgref.relative) then {
          if (link.href.extname == ".eps") log("filesRefer",link.href) // refer to eps too
          log("filesRefer",imgref);
          log("embed", imgref);
        }
        imgref.escape
      }
    }    
    "<img src=\"" + href + "\"" +
      (if (link.title != "") then " title=\"" + link.title.extractText.escape + "\"" else "") +
      (if (content != "") then " alt=\"" + content.escape + "\"" else "") +
      link.linkattrs.htmlFormat("img",context.sanitize) + ">"
  }
  else {
    "<a href=\"" + link.href.escape + "\"" +
      (if (link.title != "") then " title=\"" + link.title.extractText.escape + "\"" else "") +
      link.linkattrs.htmlFormat("a",context.sanitize) + ">" + 
      content + "</a>"
  }
}

function extractText( s : string ) : string {
  s.replaceAll(rxTag,"")
}

val rxTag = regex(@"<[^\n>]*>")

public function fmtHtmlCodePlain( context : inlineContext, txt : string ) : string 
{
  txt.escapePre  
}

public function fmtHtmlCodeHilite( context : inlineContext, txt : string, startLine : bool ) : (string) 
{
  txt.replaceAll(rxEndSpaces," ")
}
val rxEndSpaces = regex(@"  +$")

public function fmtHtmlCodeToken( classes : list<string> , txt : string ) : string {
  "<span class='" + classes.join(" ").replaceAll("'","") + "'>" + txt + "</span>"
}

/* --------------------------------------
 Format attributes 
---------------------------------------- */

// Format attributes. If none, return the empty string, otherwise start with a space
public function htmlFormat( attrs : attrs, tag : string, sanitize : bool = True ) : string {
  if (attrs.empty || sanitize) then return ""
  (if (attrs.name=="") then "" else " id=\"" + escape(attrs.name) + "\"") +
   (if (attrs.classes.isNil) then "" 
     else " class=\"" + escape(attrs.classes.join(" ")) + "\"") 
   + attrs.formatKeyvals(tag)
   // (" input=" + attrs.input.maybe("?",showInput)) +
   //(attrs.htmlAttributes)
}

function formatKeyvals( attrs : attrs, tag : string ) {
  val kvs = attrs.keyvals.map fun(kv) {
    formatKeyval(kv.fst,kv.snd,tag)
  }
  val (hstyles,hattrs) = kvs.partition( fun(kv){ kv.contains(rxColon) } )
  (if (hattrs.isNil) then "" else " " + hattrs.join(" ")) + 
   (if (hstyles.isNil) then "" else " style=" + hstyles.join(";").htmlQuote )
}
val rxColon = regex(@"^[\w\-]+\s*:")

function formatKeyval( key : string, value : string, tag : string ) {
  if (key.startsWith("html-")) {
    key.substr(5) + "=" + value.htmlQuote
  }
  elif (key.startsWith("tex-")) {
    ""
  }
  elif (key.startsWith("data-")) {
    key + "=" + value.htmlQuote
  }
  elif (key.startsWith("css-")) {
    key.substr(4).escape + ":" + value.cssQuote
  }
  elif ((key=="colspan" || key=="column-span") && (tag=="td" || tag=="th")) {
    "colspan=" + value.htmlQuote
  }
  elif ( // ((key=="width") && (tag=="td" || tag=="th")) ||
        (key=="target" && tag=="a") ||
        (key=="start" && tag=="ol"))
  {
    key + "=" + value.htmlQuote
  }
  //elif ((key=="align" || key=="text-align") && (tag=="td" || tag=="th")) {
  //  "align=" + value.htmlQuote
  //}
  elif ((key=="width" || key=="height" || key=="text-align") && (tag=="span")) {
    "display: inline-block; " + key + ":" + cssQuote(value) 
  }
  elif (value=="" || (key=="toc" || key=="toc-line" || key=="toc-depth" || 
          key=="toctarget" || key=="toclevel" ||
          key=="language" || key=="bibdata" || key=="caption" || key=="cite-label")) {
    "" // nothing
  }
  else {
    key.escape + ":" + value.cssQuote
  }
}

function htmlQuote(s) {
  "\"" + s.escape + "\""
}

function cssQuote(s :string) {
  s.list.map(cssEscape).join
}

function cssEscape(c) {
  if (c >= ' ' && c <= '~' && c != '\\') // && c != '"' && c != '\'' && c != '<' && c != '>') 
   then c.string
   else  "\\" + c.int.showHex() + " "
}

// private function htmlAttributes( attrs : attrs ) :  string {
//   attrs.keyvals.map(fun(kv) {
//     " " + kv.fst + "=\"" + kv.snd.escape + "\""
//   }).join()
// }

/* --------------------------------------
 Tags 
---------------------------------------- */

// output a html tag with a given body and attributes
public function tag( tagName : string, body : string, attrs : string = "" ) : string 
{
  "<" + tagName + 
   attrs + // (if (attrs.startsWith(" ")) then attrs else (" " + attrs)) +  
   ">" + body + "</" + tagName + ">"
}


// output a html block tag
public function tagEnv( tagName : string, body : string, attrs : attrs = attrsNone, sanitize : bool = True ) : string 
{
  tagBlock( tagName, body, attrs.htmlFormat(tagName,sanitize))
}

// output a html block tag
function tagBlock( tagName : string, body : string, attrs : string = "" ) : string 
{
  "\n<" + tagName + 
   attrs + // (if (attrs.startsWith(" ")) then attrs else (" " + attrs)) +  
   ">" + body + "</" + tagName + ">"
}


/* --------------------------------------
  Title 
---------------------------------------- */
function fmtField( context: inlineContext, elem :string, class : string, txt : string ) : string {
  if (txt=="") return ""
  tag(elem, context.formatInline(txt), " class='" + class + "'")
}

public function fmtHtmlTitle(context : inlineContext, titleinfo : titleinfo ) : string {
  tag("section", 
    [tag("h1",context.formatInline(titleinfo.title)," class='title' data-line='1'"),
     if (titleinfo.subtitle=="") then "" else tag("h2",context.formatInline(titleinfo.subtitle)," class='subtitle'"),
     context.fmtField("div","titlenote",titleinfo.note),     
     tag("table",
      tag("tr", 
       titleinfo.authors.map(fun(author) {
        tag("td", context.fmtField("div","author",author.name) +
                  context.fmtField("div","affiliation address",author.address) +
                  context.fmtField("div","email",author.email) +
                  context.fmtField("div","authornote",author.note)
           ," class='authorblock align-center'")
       }).join("\n"))),
    ].join("\n"),
    " class='titleblock align-center'")
   
}

/* --------------------------------------
  Full header 
---------------------------------------- */
public function fmtHtmlFull(html : string, options : options, metadata : dict<string> ) : string 
{
  function expand(s) { s.expandKeys(metadata) }

  function makeMeta(name : string, sep : string = "" ) : list<string> {
    match (metadata[name]) {
      Nothing -> []
      Just(value) -> {
        val evalue = value.expand.escape
        ["name=\"" + name.escape + "\" content=\"" + 
          (if (sep=="") then evalue else evalue.replaceAll(";",sep)) + "\""]
      }
    }
  }

  val extensions = options.mjext.expand.splitPaths.map(fun(path) { 
      htmlQuote( (if (path.endsWith(".js")) then path else path + ".js") )
    }).join(",")

  val meta = options.htmlMeta.expand.splitPaths + 
              makeMeta("copyright") +
              makeMeta("license") +
              makeMeta("keywords",",") + 
              makeMeta("author",",") +
              makeMeta("description") 
              
  "<!DOCTYPE html>\n<html>\n<head>\n" +
   "  <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\" />\n" +
   "  <meta name=\"generator\" content=\"Madoko, version " + version + "\" />\n" +
   meta.map(fun(m) { "  <meta " + m + " />\n" }).join +
   (if (options.title=="") then "" else
      "  <title>" + escape(options.title.expand) + "</title>\n") +
   (if (options.css == "") then "" else {
      val links = options.css.expand.splitPaths
      links.map(fun(link) { 
        match(options.embedinfos[link]) {
          Just(info) | info.embedData != "" -> 
            "  <style>\n" + info.embedData + "\n  </style>\n"
          _ -> {
            if (link.relative) then {
              log("filesRefer",link);
              log("embed",link);
            }
            "  <link rel=\"stylesheet\" type=\"text/css\" href=\"" + escape(link) + "\">\n"             
          }
        }
      }).join 
    }) +
   (if (options.scripts == "") then "" else {
      val xlinks = options.scripts.expand.splitPaths
      xlinks.map(fun(xlink) { 
        val (link,attrs) = match(xlink.find(rxScript)) {
          Nothing   -> (xlink,attrsNone)
          Just(cap) -> (cap.groups[1],parseAttrs( cap.groups[2], "script"))
        }
        match(options.embedinfos[link]) {
          Just(info) | info.embedData != "" -> 
            "  <script " + attrs.htmlFormat("script",False) + ">\n" + info.embedData + "\n  </script>\n"
          _ -> {
            if (link.relative) then {
              log("filesRefer",link);
              log("embed",link);
            }
            "  <script src=\"" + escape(link) + "\" " + attrs.htmlFormat("script",False) + "></script>\n" 
          }
        }
      }).join 
    }) +
   (if (/* options.mathmode.isStatic ||*/ options.mathjax=="") then "" else {
      ["  <script type=\"text/x-mathjax-config\">",
       "  MathJax.Hub.Config({",
       "    tex2jax: {inlineMath: [['$','$']]},",
       @"     TeX: { ",
       @"       Macros: { mathid: ['\\mathit{#1\\hspace{0.1ex}}',1], mathkw: ['\\mathsf{#1}',1],",
       @"                 mathspace: ['\\hspace{#1pt}\\hspace{#1pt}\\hspace{#1pt}',1], mathindent: ['\\hspace{#1ex}',1], mathbr: ['\\\\'],",
       @"               },",
       if (extensions=="") then "" 
        else @"       extensions: [" + extensions + "]",
       @"     }",
       "  });",
       "  MathJax.Hub.Register.StartupHook('TeX AMSmath Ready',function () { ",
       "    MathJax.InputJax.TeX.Definitions.environment['mdMathprearray'] = ['AMSarray',null,null,null,'l','0em','0em'];", 
       "  });", 
       "</script>",
       "<script type=\"text/javascript\"",
       "  src=\"" + options.getMathjax.expand.escape + "\">",
       "</script>\n"
      ].join("\n  ")
   }) +
   options.htmlHeader.expand + "\n" + 
   "</head>\n" +
   "<body class=\"madoko\">\n" + 
   html +
   "\n</body>\n" +
   options.htmlFooter.expand + "\n" + 
   "</html>\n"
}

val rxScript = regex(@"([^\{\s]+)\s*(?:\{((?:[^\\\}]|\\.)*)\})?")



/* --------------------------------------
  Escape HTML Elements 
---------------------------------------- */

function escape( s : string ) :  string
{
  s.htmlEscape(allowEntity=True)
}

function escapePre( s : string ) :  string
{
  s.htmlEscape()  
}

public function htmlEscape( s : string, allowEntity : bool = False ) {
  if (s.contains(rxhtml)) 
   then s.replaceAll( if (allowEntity) then rxnoEntityAmp else rxamp,"&amp;")
         .replaceAll(rxlt,"&lt;").replaceAll(rxgt,"&gt;")
         .replaceAll(rxquot,"&quot;").replaceAll(rxapos,"&#39;")
   else s        
}
val rxnoEntityAmp = regex(@"&(?!#?\w+;)")
val rxamp = regex(@"&")
val rxgt  = regex(@">")
val rxlt  = regex(@"<")
val rxquot = regex("\"")
val rxapos = regex("'")
val rxhtml = regex(@"[&<>""']")


function escapeChar( c : string ) : string 
{
  if (c=="&") "&amp;"
  elif (c==">") "&gt;"
  elif (c=="<") "&lt;"
  elif (c=="\"") "&quot;"
  elif (c=="'") "&#39;"
  else c
}
