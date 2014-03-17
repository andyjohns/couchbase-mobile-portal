<?xml version="1.0"?>
<!DOCTYPE xml [
  <!ENTITY left-chevron "〈">
  <!ENTITY right-chevron "〉">
]>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:file="java:java.io.File"
    xmlns:fn="http://www.couchbase.com/xsl/extension-functions"
    exclude-result-prefixes="fn file">

<xsl:output method="xhtml" indent="no" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>

<xsl:include href="search-index.xslt"/>
	
<xsl:param name="index-search" select="true()"/>
<xsl:param name="languages" select="distinct-values(//@language)"/>

<!-- =========== -->
<!-- Entry Point -->
<!-- =========== -->

<xsl:template match="/">
	<xsl:apply-templates select="//set"/>
	<xsl:apply-templates select="//guide"/>
	<xsl:apply-templates select="//article"/>
	<xsl:apply-templates select="//class"/>
	<xsl:apply-templates select="//lesson"/>
	<xsl:apply-templates select="//page"/>
	
	<!-- Copy Resources -->
	<xsl:variable name="resource-directories">styles scripts images</xsl:variable>
	<xsl:variable name="source-base-directory" select="string(file:getParent(file:new(base-uri())))"/>
	<xsl:variable name="destination-base-directory" select="string(fn:result-directory(.))"/>
	<xsl:for-each select="tokenize($resource-directories, ' ')">
		<xsl:value-of select="fn:copy-directory(file:getAbsolutePath(file:new($source-base-directory, string(.))), file:getAbsolutePath(file:new($destination-base-directory)))"/>
	</xsl:for-each>
	
	<!-- Search & Indexing -->
	<xsl:if test="$index-search">
		<xsl:apply-templates select="." mode="search"/>
		
		<xsl:result-document href="{concat($output-directory, 'scripts/search-index.js')}" method="text">
			<xsl:apply-templates select="." mode="search-index"/>
		</xsl:result-document>
		
		<xsl:result-document href="{concat($output-directory, 'scripts/search-index-advanced.js')}" method="text">
			<xsl:apply-templates select="." mode="search-index-advanced"/>
		</xsl:result-document>
	</xsl:if>
</xsl:template>

<!-- ==================== -->
<!-- Common Page Template -->
<!-- ==================== -->

<xsl:template match="*" mode="wrap-page">
	<xsl:param name="header"/>
	<xsl:param name="content"/>
	
	<html>
		<head>
			<title>
				<xsl:variable name="site-title" select="ancestor-or-self::site/title"/>
				<xsl:value-of select="fn:iif(title != $site-title, concat(title, ' | ', $site-title), $site-title)"/>
			</title>
			
			<link rel="stylesheet" type="text/css" href="{fn:root-path(., 'styles/style.css')}"/>
			
			<!-- Include language stripes as inline styles. -->
			<xsl:for-each select="$languages">
				<xsl:variable name="stripe" select="."/>
				
				<style class="language-stripe" id="language-stripe-{$stripe}" type="text/css" disabled="true">
					<xsl:for-each select="$languages">
						<xsl:variable name="language" select="."/>
						
						<xsl:value-of select="concat('span.stripe-display.', $language, '{display:')"/>
						<xsl:value-of select="concat(fn:iif($language=$stripe, 'inline', 'none'),';}')"/>
						
						<xsl:value-of select="concat('a.tab.stripe-active.', $language, '{background:')"/>
						<xsl:value-of select="concat(fn:iif($language=$stripe, 'rgba(0, 0, 0, 0.05)', 'transparent'),';}')"/>
					</xsl:for-each>
				</style>
			</xsl:for-each>
			
			<script>
				var rootPath = <xsl:value-of select="concat('&quot;', fn:root-path(., ''), '&quot;;')"/>
			</script>
			
			<script src="{fn:root-path(., 'scripts/core.js')}"/>
			<script src="{fn:root-path(., 'scripts/search.js')}"/>
			<script src="{fn:root-path(., 'scripts/search-index.js')}"/>
			
			<xsl:copy-of select="$header"/>
		</head>
		<body>
			<xsl:apply-templates select="ancestor-or-self::site/site-map">
				<xsl:with-param name="active" select="."/>
			</xsl:apply-templates>
			
			<div class="page-wrapper">
				<xsl:apply-templates select="." mode="navigator">
					<xsl:with-param name="active" select="."/>
				</xsl:apply-templates>
				
				<xsl:if test="$content">
					<article class="content-wrapper">
						<xsl:copy-of select="$content"/>
					</article>
				</xsl:if>
			</div>
		</body>
	</html>
</xsl:template>
	
<!-- ====== -->
<!-- Search -->
<!-- ====== -->

<xsl:template match="/" mode="search">
	<xsl:result-document href="{concat($output-directory, 'search.html')}">
		<html>
			<head>
				<title>
					<xsl:value-of select="concat('Search | ', site/title)"/>
				</title>
				
				<link rel="stylesheet" type="text/css" href="{fn:root-path(., 'styles/style.css')}"/>
				
				<script>
					var rootPath = <xsl:value-of select="concat('&quot;', fn:root-path(., ''), '&quot;;')"/>
				</script>
				
				<script src="{fn:root-path(., 'scripts/core.js')}"/>
				<script defer="defer" src="{fn:root-path(., 'scripts/search-advanced.js')}"/>
				<script src="{fn:root-path(., 'scripts/search-index.js')}"/>
				<script src="{fn:root-path(., 'scripts/search-index-advanced.js')}"/>
			</head>
			<body>
				<xsl:apply-templates select="site/site-map">
					<xsl:with-param name="active" select="."/>
					<xsl:with-param name="excludeSearch" select="true()"/>
				</xsl:apply-templates>
				
				<div class="page-wrapper">
					<!-- Search -->
					<table class="search advanced">
						<tr>
							<td>
								<img alt="Search" src="{fn:root-path(., 'images/search-icon.svg')}" />
							</td>
							<td>
								<input id="search" type="text" onkeyup="search_onkeyup(this)" onchange="search_onchange(this)"/>
							</td>
						</tr>
					</table>
					
					<!-- Search Results -->
					<div id="search-results" class="advanced"/>
				</div>
			</body>
		</html>
	</xsl:result-document>
</xsl:template>

<!-- ========= -->
<!-- Navigator -->
<!-- ========= -->
	
<xsl:template match="site-map">
	<xsl:param name="active"/>
	<xsl:param name="excludeSearch" select="false()"/>
	
	<div class="page-header">
		<div class="navigator-bar-wrapper">
			<table class="navigator-bar first">
				<tr class="items">
					<td>
						<a class="dark title" href="">
							<image alt="Couchbase" src="{fn:root-path($active, 'images/site-icon.svg')}" width="32px" height="16px" />
							<nobr>Mobile Developers</nobr>
						</a>
					</td>
					
					<xsl:apply-templates select="item|group">
						<xsl:with-param name="active" select="$active"/>
					</xsl:apply-templates>
					
					<!-- Spring -->
					<td width="100%"/>
					
					<xsl:if test="not($excludeSearch)">
						<td>
							<!-- Search -->
							<table class="search">
								<tr>
									<td>
										<img alt="Search" src="{fn:root-path($active, 'images/search-icon.svg')}" />
									</td>
									<td>
										<input type="text" onkeyup="search_onkeyup(this)" onchange="search_onchange(this)" onfocus="search_onfocus(this)" onblur="search_onblur(this)"/>
									</td>
								</tr>
							</table>
						</td>
					</xsl:if>
				</tr>
			</table>
			
			<xsl:if test="not($excludeSearch)">
				<!-- Search Results -->
				<div class="search-results-wrapper">
					<div class="search-results-floater">
						<div id="search-results" class="hidden"/>
					</div>
				</div>
			</xsl:if>
		</div>
		
		<!-- Secondary Navigators -->
		<table class="navigator-bar">
			<tr class="items">
				<xsl:apply-templates select="group[descendant-or-self::*[fn:equals(self::*, $active)]]/item">
					<xsl:with-param name="active" select="$active"/>
				</xsl:apply-templates>
				<!-- Spring -->
				<td width="100%"/>
			</tr>
		</table>
	</div>
</xsl:template>

<xsl:template match="group[parent::site-map] | item[parent::site-map or parent::group[parent::site-map]]">
	<xsl:param name="active"/>
	
	<td>
		<a class="dark">
			<xsl:attribute name="href">
				<xsl:choose>
					<xsl:when test="@href">
						<xsl:value-of select="@href"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="fn:relative-result-path($active, descendant-or-self::*[self::set or self::guide or self::class or self::article or self::lesson or self::page][1])"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:attribute name="class">
				<xsl:text>dark</xsl:text>
				<xsl:if test="descendant-or-self::*[fn:equals(self::*, $active)]"> active</xsl:if>
			</xsl:attribute>
			
			<xsl:value-of select="@title"/>
		</a>
	</td>
</xsl:template>

<xsl:template match="set | guide | class | article | lesson | page" mode="navigator">
	<xsl:variable name="active" select="."/>
	
	<nav>
		<ul class="nav-list">
			<xsl:variable name="set" select="ancestor-or-self::*[self::set or self::guide or self::class or self::article or self::lesson or self::page][last()]"/>
			
			<xsl:apply-templates select="$set/../*[self::set or self::guide or self::class or self::article or self::lesson or self::page]" mode="navigator-item">
				<xsl:with-param name="active" select="$active"/>
			</xsl:apply-templates>
		</ul>
	</nav>
</xsl:template>

<xsl:template match="set | guide | class" mode="navigator-item">
	<xsl:param name="active"/>
	
	<li>
		<xsl:attribute name="class">
			<xsl:choose>
				<xsl:when test="ancestor::*[self::set or self::guide or self::class]">nav-subsection</xsl:when>
				<xsl:otherwise>nav-section</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="descendant-or-self::*[fn:equals(self::*, $active)]"> expanded</xsl:if>
		</xsl:attribute>
		
		<div onclick="toggleExpanded(this.parentNode)">
			<xsl:attribute name="class">
				<xsl:text>header</xsl:text>
				<xsl:if test="fn:equals(self::*, $active)"> active</xsl:if>
			</xsl:attribute>
			
			<a href="{fn:relative-result-path($active, .)}">
				<xsl:value-of select="title"/>
			</a>
		</div>
		
		<xsl:for-each select="descendant::*[self::set or self::guide or self::class or self::article or self::lesson or self::page][1]">
			<ul>
				<xsl:apply-templates select="." mode="navigator-item">
					<xsl:with-param name="active" select="$active"/>
				</xsl:apply-templates>
				
				<xsl:for-each select="following-sibling::*[self::set or self::guide or self::class or self::article or self::lesson or self::page]">
					<xsl:apply-templates select="." mode="navigator-item">
						<xsl:with-param name="active" select="$active"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</ul>
		</xsl:for-each>
	</li>
</xsl:template>

<xsl:template match="article | lesson | page" mode="navigator-item">
	<xsl:param name="active"/>
	
	<li class="nav-item">
		<xsl:attribute name="class">
			<xsl:choose>
				<xsl:when test="fn:equals(self::*, $active)">nav-item active</xsl:when>
				<xsl:otherwise>nav-item</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
		
		<a href="{fn:relative-result-path($active, .)}">
			<xsl:value-of select="title"/>
		</a>
	</li>
</xsl:template>

<!-- ==== -->
<!-- Sets -->
<!-- ==== -->

<xsl:template match="set">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="body/*"/>
				
				<ul class="set-item-list">
					<xsl:variable name="set" select="."/>
					
					<xsl:for-each select="items/*">
						<li>
							<a class="title" href="{fn:relative-result-path($set, .)}">
								<h2>
									<xsl:value-of select="title"/>
								</h2>
							</a>
							
							<xsl:choose>
								<xsl:when test="icon/image">
									<img class="icon" src="{fn:root-path($set, concat('images/', icon/image/@href))}" alt="{icon/image/@alt}"/>
								</xsl:when>
								<xsl:when test="self::class">
									<img class="icon" src="{fn:root-path($set, 'images/class-icon.svg')}" alt="Class"/>
								</xsl:when>
								<xsl:when test="self::guide">
									<img class="icon" src="{fn:root-path($set, 'images/guide-icon.svg')}" alt="Guide"/>
								</xsl:when>
							</xsl:choose>
							
							<p class="description">
								<xsl:value-of select="description"/>
							</p>
							
							<ul class="item-list">
								<xsl:for-each select="items/* | lessons/lesson | articles/article">
									<li>
										<a href="{fn:relative-result-path($set, .)}">
											<xsl:value-of select="title"/>
										</a>
									</li>
								</xsl:for-each>
							</ul>
						</li>
					</xsl:for-each>
				</ul>
				
				<hr/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<!-- ======== -->
<!-- Training -->
<!-- ======== -->

<xsl:template match="class">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<xsl:apply-templates select="." mode="toc"/>
				
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="introduction/*"/>
				
				<xsl:if test="lessons/lesson">
					<h2>Lessons</h2>
					<hr/>
					<dl>
						<xsl:variable name="class" select="."/>
						
						<xsl:for-each select="lessons/lesson">
							<dt>
								<a href="{fn:relative-result-path($class, .)}">
									<xsl:value-of select="title"/>
								</a>
							</dt>
							<dd>
								<xsl:value-of select="description"/>
							</dd>
						</xsl:for-each>
					</dl>
				</xsl:if>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<xsl:template match="class" mode="toc">
	<div class="toc">
		<div class="class-nav">
			<a class="first">
				<xsl:choose>
					<xsl:when test="lessons/lesson">
						<xsl:attribute name="href">
							<xsl:value-of select="fn:relative-result-path(., lessons/lesson[1])"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="class">first disabled</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:text>Get started &right-chevron;</xsl:text>
			</a>
		</div>
		
		<xsl:if test="lessons/lesson">
			<h2>This class teaches you about</h2>
			<ol>
				<xsl:variable name="class" select="."/>
				
				<xsl:for-each select="lessons/lesson">
					<li>
						<a href="{fn:relative-result-path($class, .)}"><xsl:value-of select="title"/></a>
					</li>
				</xsl:for-each>
			</ol>
		</xsl:if>
		
		<xsl:if test="dependencies/item">
			<h2>Dependencies &amp; prerequisites</h2>
			<ul>
				<xsl:for-each select="dependencies/item">
					<li>
						<xsl:apply-templates select="text()|*"/>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if>
		
		<xsl:if test="related/item">
			<h2>You should also read</h2>
			<ul>
				<xsl:for-each select="related/item">
					<li>
						<xsl:apply-templates select="text()|*"/>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</div>
</xsl:template>

<xsl:template match="lesson">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<xsl:apply-templates select="." mode="toc"/>
				
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="introduction/*"/>
				
				<xsl:apply-templates select="tasks/task"/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<xsl:template match="lesson" mode="toc">
	<div class="toc">
		<div class="lesson-nav">
			<a class="first">
				<xsl:choose>
					<xsl:when test="preceding-sibling::lesson">
						<xsl:attribute name="href">
							<xsl:value-of select="fn:relative-result-path(., preceding-sibling::lesson)"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="class">first disabled</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:text>&left-chevron; Previous</xsl:text>
			</a>
			<a>
				<xsl:choose>
					<xsl:when test="following-sibling::lesson">
						<xsl:attribute name="href">
							<xsl:value-of select="fn:relative-result-path(., following-sibling::lesson)"/>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="class">disabled</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:text>Next &right-chevron;</xsl:text>
			</a>
		</div>
		
		<xsl:if test="descendant::task">
			<h2>This lesson teaches you to</h2>
			<ol>
				<xsl:for-each select="descendant::task">
					<li>
						<a href="#{@id}"><xsl:value-of select="title"/></a>
					</li>
				</xsl:for-each>
			</ol>
		</xsl:if>
		
		<xsl:if test="related/item">
			<h2>You should also read</h2>
			<ul>
				<xsl:for-each select="related/item">
					<li>
						<xsl:apply-templates select="text()|*"/>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</div>
</xsl:template>

<xsl:template match="task">
	<h2 id="{@id}">
		<xsl:value-of select="title"/>
	</h2>
	<hr />
	
	<xsl:apply-templates select="body/(*|text())"/>
</xsl:template>

<!-- ====== -->
<!-- Guides -->
<!-- ====== -->

<xsl:template match="guide">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="." mode="toc"/>
				
				<xsl:apply-templates select="introduction/*"/>
				
				<xsl:if test="articles/article">
					<h2>Articles</h2>
					<hr/>
					<dl>
						<xsl:variable name="article" select="."/>
						
						<xsl:for-each select="articles/article">
							<dt>
								<a href="{fn:relative-result-path($article, .)}">
									<xsl:value-of select="title"/>
								</a>
							</dt>
							<dd>
								<xsl:value-of select="description"/>
							</dd>
						</xsl:for-each>
					</dl>
				</xsl:if>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<xsl:template match="guide" mode="toc">
	<xsl:if test="articles/article or dependencies/item or related/item">
		<div class="toc">
			<xsl:if test="articles/article">
				<h2>In this guide</h2>
				<ul class="plain">
					<xsl:variable name="guide" select="."/>
					
					<xsl:for-each select="articles/article">
						<li>
							<a href="{fn:relative-result-path($guide, .)}"><xsl:value-of select="title"/></a>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
			
			<xsl:if test="dependencies/item">
				<h2>Dependencies &amp; prerequisites</h2>
				<ul>
					<xsl:for-each select="dependencies/related-item">
						<li>
							<xsl:apply-templates select="text()|*"/>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
			
			<xsl:if test="related/item">
				<h2>See also</h2>
				<ul>
					<xsl:for-each select="related/item">
						<li>
							<xsl:apply-templates select="text()|*"/>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
		</div>
	</xsl:if>
</xsl:template>

<xsl:template match="article">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="." mode="toc"/>
				
				<xsl:apply-templates select="introduction/*"/>
				
				<xsl:apply-templates select="topics/topic"/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<xsl:template match="article" mode="toc">
	<xsl:if test="descendant::topic or related/item">
		<div class="toc">
			<xsl:if test="topics/topic">
				<h2>In this document</h2>
				<ul class="plain">
					<xsl:for-each select="topics/topic">
						<li>
							<a href="#{@id}"><xsl:value-of select="title"/></a>
							
							<xsl:if test="introduction/section">
								<ul>
									<xsl:for-each select="introduction/section">
										<li>
											<a href="#{@id}"><xsl:value-of select="title"/></a>
										</li>
									</xsl:for-each>
								</ul>
							</xsl:if>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
			
			<xsl:if test="related/item">
				<h2>See also</h2>
				<ul class="plain">
					<xsl:for-each select="related/item">
						<li>
							<xsl:apply-templates select="text()|*"/>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:if>
		</div>
	</xsl:if>
</xsl:template>

<xsl:template match="topic">
	<h2 id="{@id}">
		<xsl:value-of select="title"/>
	</h2>
	<hr />
	
	<xsl:apply-templates select="body/(text()|*)"/>
</xsl:template>

<!-- ==== -->
<!-- Page -->
<!-- ==== -->

<xsl:template match="page">
	<xsl:result-document href="{fn:result-path(.)}">
		<xsl:apply-templates select="." mode="wrap-page">
			<xsl:with-param name="content">
				<h1>
					<xsl:value-of select="title"/>
				</h1>
				
				<xsl:apply-templates select="body/(text()|*)"/>
			</xsl:with-param>
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<!-- ====== -->
<!-- Common -->
<!-- ====== -->

<xsl:template match="section">
	<h3 id="{@id}">
		<xsl:value-of select="title"/>
	</h3>
	
	<xsl:apply-templates select="body/*"/>
</xsl:template>
	
<xsl:template match="subsection">
	<h4 id="{@id}">
		<xsl:value-of select="title"/>
	</h4>
	
	<xsl:apply-templates select="body/*"/>
</xsl:template>

<xsl:template match="paragraph">
	<p>
		<xsl:apply-templates select="text()|*"/>
	</p>
</xsl:template>

<xsl:template match="image">
	<!-- Copy the image from the source, to the destination. -->
	<xsl:variable name="source-file" select="file:new(string(fn:base-direcotry(.)), string(@href))"/>
	<xsl:variable name="destination-file" select="file:new(string(fn:result-directory(.)), string(@href))"/>
	<xsl:value-of select="fn:copy-file(file:getAbsolutePath($source-file), file:getAbsolutePath($destination-file))"/>
	
	<img src="{@href}" alt="{@alt}" width="{@width}" height="{@height}"/>
</xsl:template>

<xsl:template match="figure">
	<div>
		<xsl:attribute name="class">
			<xsl:text>figure</xsl:text>
			<xsl:choose>
				<xsl:when test="@importance='high'"> high</xsl:when>
				<xsl:when test="@importance='normal'"> normal</xsl:when>
				<xsl:otherwise> low</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
		
		<xsl:choose>
			<xsl:when test="@width">
				<xsl:attribute name="style">
					<xsl:text>width:</xsl:text>
					<xsl:value-of select="@width"/>
				</xsl:attribute>
			</xsl:when>
			<xsl:when test="descendant::*/@width">
				<xsl:attribute name="style">
					<xsl:text>width:</xsl:text>
					<xsl:value-of select="descendant::*/@width"/>
				</xsl:attribute>
			</xsl:when>
		</xsl:choose>
		
		<xsl:apply-templates select="*[not(self::description)]"/>
		
		<xsl:if test="description">
			<div class="caption">
				<xsl:variable name="base-uri" select="base-uri()"/>
				
				<span class="tag">Figure <xsl:value-of select="count(preceding::fig[description and base-uri()=$base-uri]) + 1"/>.</span>
				<xsl:apply-templates select="description[1]/(text()|*)"/>
			</div>
		</xsl:if>
	</div>
</xsl:template>
	
<xsl:template match="code">
	<code>
		<xsl:apply-templates select="text()"/>
	</code>
</xsl:template>
	
<xsl:template match="code-block">
	<pre>
		<code>
			<!-- Get the number of leading spaces on the 1st line. -->
			<xsl:variable name="lines" select="tokenize(replace(text(), '\t', '    '), '\n\r?')"/>
            <xsl:variable name="firstLine" select="fn:iif(string-length($lines[1]) > 0, $lines[1], $lines[2])"/>
			<xsl:variable name="indentSize" select="string-length(substring-before($firstLine, substring(normalize-space($firstLine), 1, 1))) + 1"/>
			
			<xsl:for-each select="text()|*">
				<xsl:variable name="linePosition" select="position()"/>
				<xsl:variable name="lastLinePosition" select="last()"/>
				
				<xsl:choose>
					<xsl:when test="self::text()">
						<!-- Normalize tabs as 4-spaces. -->
						<xsl:variable name="text">
							<xsl:value-of select="replace(., '\t', '    ')"/>
						</xsl:variable>
						
						<xsl:for-each select="tokenize($text, '\n\r?')">
							<xsl:choose>
								<xsl:when test="((position()=1 and $linePosition=1) or (position()=last() and $linePosition=$lastLinePosition)) and string-length(fn:trim(.))=0">
									<!-- If they are empty, do nothing for the 1st and last line. -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="substring(., $indentSize)" />
									<xsl:text>&#10;</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</code>
	</pre>
</xsl:template>
	
<xsl:template match="code-set">
	<xsl:variable name="code-set" select="."/>
	
	<div class="tab-bar">
		<xsl:for-each select="$languages">
			<xsl:variable name="language" select="."/>
			
			<a href="javascript:setLanguage({fn:iif($language, concat('&quot;', $language, '&quot;'), 'null')})">
				<xsl:attribute name="class">
					<xsl:text>tab</xsl:text>
					<xsl:value-of select="fn:iif($language, concat(' stripe-active ', $language), '')"/>
					
					<xsl:if test="not($code-set/code-block[@language=$language])">
						<xsl:text> disabled</xsl:text>
					</xsl:if>
				</xsl:attribute>
				
				<xsl:value-of select="$language"/>
			</a>
		</xsl:for-each>
	</div>
	<xsl:for-each select="$languages">
		<xsl:variable name="language" select="."/>
		<xsl:variable name="code" select="$code-set/code-block[@language=$language]"/>
		
		<span class="stripe-display {$language}">
			<xsl:choose>
				<xsl:when test="$code">
					<xsl:apply-templates select="$code"/>
				</xsl:when>
				<xsl:otherwise>
					<pre>
					<code class="disabled">
						<xsl:text>No code example is currently available.</xsl:text>
					</code>
				</pre>
				</xsl:otherwise>
			</xsl:choose>
		</span>
	</xsl:for-each>
</xsl:template>

<xsl:template match="ref">
	<a>
		<xsl:if test="@href">
			<!-- TODO: Resolve internal target. -->
		</xsl:if>
		
		<xsl:value-of select="."/>
	</a>
</xsl:template>
	
<xsl:template match="external-ref">
	<a>
		<xsl:if test="@href">
			<xsl:attribute name="href" select="@href"/>
		</xsl:if>
		
		<xsl:value-of select="."/>
	</a>
</xsl:template>

<xsl:template match="emphasis">
	<em>
		<xsl:apply-templates select="text()|*"/>
	</em>
</xsl:template>

<xsl:template match="strong">
	<strong>
		<xsl:apply-templates select="text()|*"/>
	</strong>
</xsl:template>

<xsl:template match="ordered-list">
	<ol>
		<xsl:apply-templates select="list-item"/>
	</ol>
</xsl:template>

<xsl:template match="unordered-list">
	<ul>
		<xsl:apply-templates select="list-item"/>
	</ul>
</xsl:template>

<xsl:template match="description-list">
	<dl>
		<xsl:apply-templates select="entry"/>
	</dl>
</xsl:template>

<xsl:template match="list-item">
	<li>
		<xsl:apply-templates select="text()|*"/>
	</li>
</xsl:template>

<xsl:template match="entry">
	<dt>
		<xsl:apply-templates select="title[1]/(text()|*)"/>
	</dt>
	<dd>
		<xsl:apply-templates select="description[1]/(text()|*)"/>
	</dd>
</xsl:template>

<xsl:template match="note">
	<div>
		<xsl:attribute name="class">
			<xsl:text>note</xsl:text>
			<xsl:choose>
				<xsl:when test="@type='tip'"> tip</xsl:when>
				<xsl:when test="@type='caution'"> caution</xsl:when>
			</xsl:choose>
		</xsl:attribute>
		
		<span class="tag">
			<xsl:choose>
				<xsl:when test="@type='tip'">Tip:</xsl:when>
				<xsl:when test="@type='caution'">Caution:</xsl:when>
				<xsl:otherwise>Note:</xsl:otherwise>
			</xsl:choose>
		</span>
		
		<xsl:apply-templates select="text()|*"/>
	</div>
</xsl:template>
	
<xsl:template match="table">
	<div class="table">
		<table>
			<xsl:for-each select="header">
				<thead>
					<xsl:for-each select="row">
						<tr>
							<xsl:for-each select="entry">
								<th>
									<xsl:if test="@colspan">
										<xsl:attribute name="colspan" select="@colspan"/>
									</xsl:if>
									<xsl:if test="@rowspan">
										<xsl:attribute name="rowspan" select="@rowspan"/>
									</xsl:if>
									
									<xsl:apply-templates select="text()|*"/>
								</th>
							</xsl:for-each>
						</tr>
					</xsl:for-each>
				</thead>
			</xsl:for-each>
			<xsl:for-each select="body">
				<tbody>
					<xsl:for-each select="row">
						<tr>
							<xsl:for-each select="entry">
								<td>
									<xsl:if test="@colspan">
										<xsl:attribute name="colspan" select="@colspan"/>
									</xsl:if>
									<xsl:if test="@rowspan">
										<xsl:attribute name="rowspan" select="@rowspan"/>
									</xsl:if>
									
									<xsl:apply-templates select="text()|*"/>
								</td>
							</xsl:for-each>
						</tr>
					</xsl:for-each>
				</tbody>
			</xsl:for-each>
		</table>
		
		<xsl:if test="description">
			<div class="caption">
				<xsl:variable name="base-uri" select="base-uri()"/>
				
				<span class="tag">Table <xsl:value-of select="count(preceding::table[description and base-uri()=$base-uri]) + 1"/>.</span>
				<xsl:apply-templates select="description[1]/(text()|*)"/>
			</div>
		</xsl:if>
	</div>
</xsl:template>

</xsl:stylesheet>