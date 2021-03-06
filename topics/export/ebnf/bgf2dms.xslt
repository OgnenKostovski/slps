<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:bgf="http://planet-sl.org/bgf"
    xmlns:xhtml="http://www.w3.org/1999/xhtml">

  <!--
    Using this pretty-printer on a grammar with BGF-specific features
    can lead to generation of incorrect DMS BNF grammars.
  -->
  
  <xsl:output
      method="text"
      encoding="UTF-8"
      omit-xml-declaration="yes"
      />

  <xsl:template match="/bgf:grammar">
    <xsl:apply-templates select="./bgf:*"/>
  </xsl:template>

  <xsl:template match="bgf:production">
    <!--xsl:if test="./label">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="./label"/>
      <xsl:text>] </xsl:text>
    </xsl:if-->
    <xsl:choose>
      <xsl:when test="./bgf:expression/choice">
        <xsl:for-each select="./bgf:expression/choice/bgf:expression">
          <xsl:value-of select="../../../nonterminal"/>
          <xsl:text> = </xsl:text>
          <xsl:call-template name="no-parenthesis">
            <xsl:with-param name="expr" select="."/>
          </xsl:call-template>
          <xsl:text> ;
</xsl:text>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="./bgf:expression/epsilon">
          <xsl:value-of select="./nonterminal"/>
          <xsl:text> = ;
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="./nonterminal"/>
        <xsl:text> = </xsl:text>
        <xsl:call-template name="no-parenthesis">
          <xsl:with-param name="expr" select="./bgf:expression"/>
        </xsl:call-template>
        <xsl:text> ;
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="bgf:expression">
    <xsl:apply-templates select="./*"/>
  </xsl:template>

  <xsl:template match="marked">
    <!--xsl:text><![CDATA[<]]></xsl:text-->
    <xsl:apply-templates select="./*"/>
    <!--xsl:text><![CDATA[>]]></xsl:text-->
  </xsl:template>

  <xsl:template match="plus">
    <xsl:apply-templates select="./*"/>
    <xsl:text>+</xsl:text>
  </xsl:template>

  <xsl:template match="star">
    <xsl:apply-templates select="./*"/>
    <xsl:text>*</xsl:text>
  </xsl:template>

  <xsl:template match="optional">
    <xsl:apply-templates select="./*"/>
    <xsl:text>?</xsl:text>
  </xsl:template>

  <xsl:template match="terminal">
    <xsl:text>'</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>'</xsl:text>
  </xsl:template>

  <xsl:template match="value">
    <xsl:choose>
      <xsl:when test=". = 'string'">
        <xsl:text>STR</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>INT</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="epsilon">
    <xsl:text></xsl:text>
  </xsl:template>

  <xsl:template match="empty">
    <xsl:text></xsl:text>
  </xsl:template>

  <xsl:template match="any">
    <xsl:text>ANY</xsl:text>
  </xsl:template>

  <xsl:template match="nonterminal">
    <xsl:choose>
      <xsl:when test="text() = 'identifier'">
        <xsl:text>IDENTIFIER</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	    <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="selectable">
    <xsl:value-of select="selector"/>
    <xsl:text>::</xsl:text>
    <xsl:choose>
      <xsl:when test="local-name(bgf:expression/*) = 'star'
                   or local-name(bgf:expression/*) = 'optional'
                   or local-name(bgf:expression/*) = 'plus'">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="bgf:expression"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="bgf:expression"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sequence">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="./bgf:expression[1]/*"/>
    <xsl:for-each select="./bgf:expression[position()>1]">
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="./*"/>
    </xsl:for-each>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <!-- inner choices - BNF bar -->
  <xsl:template match="choice">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="./bgf:expression[1]/*"/>
    <xsl:for-each select="./bgf:expression[position()>1]">
      <xsl:text> | </xsl:text>
      <xsl:apply-templates select="./*"/>
    </xsl:for-each>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template name="no-parenthesis">
    <xsl:param name="expr"/>
    <xsl:choose>
      <xsl:when test="$expr/sequence">
        <xsl:apply-templates select="$expr/sequence/bgf:expression[1]/*"/>
        <xsl:for-each select="$expr/sequence/bgf:expression[position()>1]">
          <xsl:text> </xsl:text>
          <xsl:apply-templates select="./*"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$expr"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
