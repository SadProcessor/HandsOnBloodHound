//    ###  CYPHER SYNTAX 101 ###

/////////////////////////////////

// ## NODES ##

// Node by Type
MATCH (x:User) RETURN x

// Node by Name
MATCH (x:User {name:'KRBTGT@CONTOSO.LOCAL'}) RETURN x

// Node by Props
MATCH (x:User {enabled:True}) RETURN x
MATCH (x:User {int:123}) RETURN x
MATCH (x:User {enabled:True}) RETURN x

// Multiple props
MATCH (x:User {int:123,enabled:True}) RETURN x
MATCH (x:User {enabled:True,owned:True}) RETURN x


// # RETURN #

// Return node
MATCH (x:User) RETURN x

// Return specific prop
MATCH (x:User) RETURN x.name

// multiple values
MATCH (x:User) RETURN x.name,x.objectid

// multiple props as obj << :)
MATCH (x:User) RETURN {Name:x.name,ID:x.objectid}

// Return node count
MATCH (x:User) RETURN COUNT(x)

// Return node labels
MATCH (x:User) RETURN LABELS(x)
MATCH (x:User) RETURN LABELS(x)[1]
MATCH (x:User) RETURN {Name:x.name,Type:LABELS(x)[1]}

// Order
MATCH (x:User) RETURN x.name ORDER BY x.name
// Limit
MATCH (x:User) RETURN x.name LIMIT 2
MATCH (x:User) RETURN x.name LIMIT 2

// # WHERE (WHERE NOT)#

// Where: property=value
MATCH (x:User) WHERE x.name='BOB@LAB.TEST' RETURN x
MATCH (x:User) WHERE x.name<>'BOB@LAB.TEST' RETURN x
MATCH (x:User) WHERE NOT x.name='BOB@LAB.TEST' RETURN x
MATCH (x:User) WHERE x.number=123 RETURN x
MATCH (x:User) WHERE NOT x.enabled=false RETURN x
MATCH (x:User) WHERE x.enabled RETURN x

// COMPARAISON OPERATORS

//  equals to         : =
//  not equal to      : <>
//  less than         : <
//  less or equal     : <=
//  greater           : >
//  greater or equal  : >=
//  null              : IS NULL
//  not null          : IS NOT NULL
//  prefix*           : STARTS WITH
//  suffix*           : ENS WITH
//  inclusion*        : CONTAINS
//  regex*            : =~

// * = string specific

MATCH (x:User) WHERE x.name =~ "(?i).*AdMin.*" RETURN x

// Where: Operators
MATCH (x:User) WHERE x.objectid ENDS WITH '-500' RETURN x
MATCH (x:User) WHERE x.objectid =~ '^S.*-500$' RETURN x

MATCH (x:User) WHERE x.lastlogon<=0 RETURN x
MATCH (x:User) WHERE x.lastlogon < (datetime().epochseconds - (90 * 86400)) RETURN x // older than 90 days
MATCH (x:User) WHERE NOT x.lastlogon IN [0,-1] AND NOT x.lastlogon > (datetime().epochseconds - (90 * 86400)) RETURN x.name


// Where: Operator/Map Combo
MATCH (x:User {enabled:True}) WHERE x.lastlogon<=0 AND x.objectid ENDS WITH '-500' RETURN x


// Where: Array...
// contains something (not empty)
MATCH (x:User)
WHERE SIZE(x.serviceprincipalnames)>0
RETURN x
// contains specific value
MATCH (x:User)
WHERE 'kadmin/changepw' IN x.serviceprincipalnames
RETURN x
// element matches
MATCH (x:User)
WHERE [mytemp IN x.serviceprincipalnames WHERE mytemp CONTAINS 'SQL']
RETURN x


// Where: Property exists
MATCH (x:User)
WHERE NOT EXISTS(x.description)
RETURN x



// Where: path condition
MATCH (x:User)
WHERE (x)-[:AdminTo]->(:Computer{name:'DC1@TEST.LAB'}) 
RETURN x


////////////////////////////////////

// ## PATH ##

// Shortest path: Any edges / no max hop
MATCH (x:User)
MATCH (y:Group {name:'DOMAIN ADMINS@COFFEE.CUP'})
MATCH p=shortestPath((x)-[*1..]->(y))
RETURN p


// Any Path : Single edge / single hop
MATCH (x:User)
MATCH (y:Group {name:'DOMAIN ADMINS@COFFEE.CUP'})
MATCH p=(x)-[:MemberOf*1]->(y)
RETURN p


// All Shortest : multiple edges / max 4 hops
MATCH (x:User)
MATCH (y:Group {name:'DOMAIN ADMINS@COFFEE.CUP'})
MATCH p=shortestPaths((x)-[:MemberOf|:AdminTo|:HasSession*1..4]->(y))
RETURN p


// Return count of paths
MATCH (x:User)
MATCH (y:Group {name:'DOMAIN ADMINS@COFFEE.CUP'})
MATCH p=shortestPath((x)-[*1..]->(y))
RETURN COUNT(p)


// Return path relationships
MATCH (x:User)
MATCH (y:Group {name:'DOMAIN ADMINS@COFFEE.CUP'})
MATCH p=shortestPath((x)-[*1..]->(y))
WITH p, [r in RELATIONSHIPS(p)| TYPE(r)] as type
RETURN {rels:type}


// Return custom objects
MATCH (x:User)
MATCH (y:Group {highvalue:True})
MATCH p=shortestPath((x)-[*1..]->(y))
RETURN {Length:LENGTH(p),Source:x.name,Target:y.name}


// Compact style (same as above)
MATCH p=shortestPath((x:User)-[*1..]->(y:Group {highvalue:True}))
RETURN {Length:LENGTH(p),Source:x.name,Target:y.name}


// Edge by edge property
MATCH p=(x:User)-[{isacl:True}]->(y:Computer) RETURN p


// Path where path
MATCH p=(x:Computer)-[:HasSession]->(y:User) 
WHERE (y)-[:MemberOf|AdminTo*1..]->(x) 
RETURN p


// Multiple return / optional path
MATCH p1=(:User)-[:MemberOf*1..]->(:Group)-[{isacl:True}]->(:GPO)
OPTIONAL MATCH p2=(:User)-[{isacl:True}]->(:GPO)
RETURN p1,p2


// Chained edges
                                                     MATCH p=()-[:Contains*1..]->(:OU) RETURN p
                                       MATCH p=()-[:GpLink]->()-[:Contains*1..]->(:OU) RETURN p
                    MATCH p=()-[{isacl:True}]->()-[:GpLink]->()-[:Contains*1..]->(:OU) RETURN p
MATCH p=()-[:MemberOf*1..]->()-[{isacl:True}]->()-[:GpLink]->()-[:Contains*1..]->(:OU) RETURN p


// Filter on path nodes collection
MATCH (dc:Computer)-[:MemberOf]->(g:Group)
WHERE g.objectid ENDS WITH '-516'
WITH COLLECT(dc) AS dcgroup
MATCH (x:Computer) WHERE NOT x IN dcgroup
RETURN x.name


///////////////////////////////////////////

//    ## Create / Modify / Delete ##

// ## NODES

// # Modify: single prop
MATCH (x:User {name:'TEST@TEST.LAB'}) SET x.enabled = True
// # Modify: mutiple props (mutate) < Safe
MATCH (x:User {name:'TEST@TEST.LAB'})
SET += {enabled=True,Highvalue=False}
// # Modify: mutiple props (force)
MATCH (x:User {name:'TEST@TEST.LAB'})
SET = {enabled=True}

// Create
MERGE (x:User {name:'Test'})
// Delete
MATCH (x:User {name:'Test'}) DETACH DELETE x


// Create: Advanced 
MERGE (x:Base {x.objectid:'ThisIsATest'}) 
SET x:User, x.name='Test'
SET += {
    bool   = True
    int    = 123
    string = 'abc'
    array  = ['abc','def','ghi']
    }
RETURN x

// Remove: Node property
MATCH (x:User {name:'Test'}) REMOVE x.string
// Remove Node Label
MATCH (x:User {name:'Test'}) REMOVE x:User



///////////////

MATCH (x:Computer {name:'PCI-SERVER-001.CONTOSO.LOCAL'}) RETURN x
MATCH (x:Computer) WHERE x.name = 'PCI-SERVER-001.CONTOSO.LOCAL' RETURN x

MATCH (x:User) x.name STARTS WITH 'SQL'
MATCH (x:User) xname =~ '^SQL.*' RETURN x

MATCH (x:Group) WHERE x.name CONTAINS 'ADMIN' RETURN x


MATCH (x:User {name:'DHOHNSTEIN@CONTOSO.LOCAL'})
MATCH (y:Group {name:'DOMAIN ADMINS@CONTOSO.LOCAL'})
MATCH path = shortestPath(x)-[*1..]->(y) RETURN path

MATCH path = shortestPath(x:User {name:'DHOHNSTEIN@CONTOSO.LOCAL'})-[*1..]->(y:Group {name:'DOMAIN ADMINS@CONTOSO.LOCAL'}) RETURN path

MATCH (x:User {name:'ACHILLES@CONTOSO.LOCAL'})
MATCH (y:Group {highvalue:True})
MATCH path = shortestPath(x)-[*1..]->(y) RETURN path


MATCH (x:User {name:'JEFFMCJUNKIN@CONTOSO.LOCAL'})
MATCH (y:Computer) WHERE y.operatingsystem CONTAINS '10'
MATCH path = shortestPath(x)-[*1..]->(y) RETURN path

MATCH (x:Group)



//================== Bits of stuffs

MATCH (u:User {name:'JEFFMCJUNKIN@CONTOSO.LOCAL'})
MATCH (g:Group {name:'DOMAIN ADMINS@CONTOSO.LOCAL'})
MATCH p=shortestPath((u)-[*1..]->(g))
RETURN p


MATCH p=shortestPath((u:User {name:'JEFFMCJUNKIN@CONTOSO.LOCAL'})-[:MemberOf|HasSession|AdminTo*1..5]->(g:Group {name:'DOMAIN ADMINS@CONTOSO.LOCAL'}) )
RETURN p



MATCH (x:Computer {name:'PCI-SERVER-001.CONTOSO.LOCAL'}) RETURN x 
MATCH (x:User) WHERE x.name STARTS WITH 'SQL' RETURN x
MATCH (x:Group) WHERE x.name CONTAINS 'ADMIN' RETURN x

MATCH (x:Group)
MATCH (y:Computer) WHERE NOT y.name<>'DESKTOP-4AMBQF0.CONTOSO.LOCAL'
MATCH p=shortestPath((x)-[*1..]->(y))
RETURN p



MATCH p=(n:Domain)-->(m:Domain) RETURN p

MATCH p=(n:Domain)-->(m:Domain) RETURN p


MATCH p=(n:Group)<-[:MemberOf]-(m) WHERE n.objectid =~ "(?i)S-1-5-.*-512" RETURN p

MATCH (n1)-[:MemberOf|GetChanges*1..]->(u:Domain {name: "CONTOSO.LOCAL"}) 
WITH n1,u 
MATCH (n1)-[:MemberOf|GetChangesAll*1..]->(u) 
WITH n1,u 
MATCH p = (n1)-[:MemberOf|GetChanges|GetChangesAll*1..]->(u) 
RETURN p


MATCH (n:User) WHERE n.hasspn=true RETURN n
MATCH (n:User) WHERE n.hasspn RETURN n
MATCH (n:User {hasspn:true}) RETURN n



MATCH (u:User {owned:True})
MATCH (g:Group {highvalue:True})
MATCH p=shortestPath((u)-[*1..]->(g))
RETURN p



MERGE (x:User {name:'JD'}) SET x.objectid='S-234567' RETURN x

MATCH (x:User {name:'SadProcessor'}) SET x.objectid=12345 RETRUn x

MATCH (x:User {name:'SadProcessor'})
MATCH (y:User {name:'JD'})
MERGE (x)-[:IsOnline]->(y)

MATCH (n:User {objectid: "S-12345"}) 
MATCH (m:User {objectid: "S-234567"}) 
MATCH p=allShortestPaths((n)-[r:IsOnline*1..]->(m)) 
RETURN p

MATCH (n:User {objectid: "S-12345"}) 
MATCH (m:User {objectid: "S-234567"}) 
DETACH DELETE n,m




MATCH (x:User {hasspn:True}) RETURN COUNT(x)

MATCH (x:User) WHERE x.hasspn=True 
WITH COUNT(x) AS KerbUserCount
RETURN KerbUserCount

MATCH p=shortestPath((x:User)-[:MemberOf|HasSession|AdminTo|AllExtendedRights|AddMember|ForceChangePassword|GenericAll|GenericWrite|Owns|WriteDacl|WriteOwner|ReadLAPSPassword|ReadGMSAPassword*1..]->(y:Group {highvalue:True})) RETURN COUNT(x)

MATCH (x:Computer) WHERE x.operatingsystem CONTAINS '2016' RETURN x  



MATCH (n1)-[:MemberOf|GetChanges*1..]->(u:Domain {name: "BSC.LOCAL"}) 
WITH n1,u MATCH (n1)-[:MemberOf|GetChangesAll*1..]->(u) 
WITH n1,u 
MATCH p = (n1)-[:MemberOf|GetChanges|GetChangesAll*1..]->(u) RETURN p


MATCH p=shortestPath((x:User)-[:MemberOf|GetChanges*1..]->(y:Domain {name: 'DomainGoesHere'}))
WHERE (x)-[:MemberOf|GetChangesAll*1..]->(y)
RETURN p




// ----------------------------------------------------- Freestyle

// Matching node per property
MATCH (pc:Computer {operatingsytem:'Windows Server 2016 Standard'}) RETURN pc
MATCH (pc:Computer) WHERE pc.operatingsystem='value' RETURN pc
// use other comp operators

// Enabled user accounts
MATCH (u:User) WHERE u.enabled=True RETURN u
MATCH (u:User) WHERE u.enabled RETURN u
// NOT enabled
MATCH (u:User) WHERE NOT u.enabled = True RETURN u
MATCH (u:User) WHERE NOT u.enabled = True RETURN u
MATCH (u:User) WHERE u.enabled = False RETURN u
MATCH (u:User) WHERE u.enabled <> True RETURN u

// enabled and match Alice
MATCH (u:User {name:'ALICE@COFFEE.CUP',enabled:True}) RETURN u

MATCH (u:User) 
WHERE u.name CONTAINS 'ALICE' AND u.enabled 
RETURN u

// PATH QUERIES

// Map Domain Trusts
MATCH p=(:Domain)-[:TrustedBy*1]->() RETURN p

// Map Domain/OU struct
MATCH p=(:Domain)-[:Contains*1..]->(:OU) RETURN p

// GPO to container map
MATCH p=(:GPO)-[:Contains|GpLink*1..]->(:OU) RETURN p
MATCH p=(:GPO)-[:Contains|GpLink*1..]->(:Computer) RETURN p

// User Can RDP?
MATCH p=shortestpath((u:User)-[*1..]->(c:Computer)) RETURN p




//

MATCH (x:Computer {name: "DC02.COFFEE.CUP"}) 
MATCH (y:Group {name: "DOMAIN ADMINS@COFFEE.CUP"}) 
MATCH p=shortestPath((x)-[r*1..]->(y)) 
RETURN p

// --------------------------------------------------------
// All DA
MATCH p=(x)-[:MemberOf*1..]->(y:Group) WHERE y.objectid =~ "(?i)S-1-5-.*-512" RETURN p

// Shortest Path to DA
MATCH p=shortestPath((x)-[*1..]->(y:Group {name:"DOMAIN ADMINS@COFFEE.CUP"})) WHERE NOT x=y RETURN p

// DCSync
MATCH (n1:User)-[:MemberOf|GetChanges*1..]->(u:Domain {name: "COFFEE.CUP"}) 
WITH n1,u 
MATCH (n1)-[:MemberOf|GetChangesAll*1..]->(u) 
WITH n1,u 
MATCH p = (n1)-[:MemberOf|GetChanges|GetChangesAll*1..]->(u) RETURN p

MATCH p=(u:User)-[:MemberOf|GetChanges*1..]->(d:Domain {name:'COFFEE.CUP'})
WHERE (u)-[:MemberOf|GetChangesAll*1..]->(d)
RETURN p

MATCH p=(u:User)-[:MemberOf|GetChanges*1..]->(d:Domain {name:'COFFEE.CUP'})
WHERE (u)-[:MemberOf|GetChangesAll*1..]->(d)
WITH *
MATCH p2=(u)-[:MemberOf|GetChangesAll*1..]->(d)
RETURN p,p2

// Foreign Group mbr
MATCH p=(u:User)-[:MemberOf]->(g:Group) WHERE g.domain<>u.domain 
RETURN p

// Domain Trust
MATCH p=()-[:TrustedBy]->() RETURN p

// Unconstrained Deleg 
MATCH p=shortestPath((n)-[*1..]->(m:Computer {unconstraineddelegation: true})) 
WHERE NOT n=m 
RETURN p

// Kerberoastable users
MATCH (x:User {domain:'COFFEE.CUP', hasspn:true}) RETURN x

// Path From Owned to Computer
MATCH p=shortestPath((x:User {owned:true})-[*1..]->(y:Computer)) RETURN p

//
match p=(g:Group {name:"DOMAIN USERS@COFFEE.CUP"})-[:CanRDP]->(c:Computer) 
where NOT c.operatingsystem CONTAINS 'Server' 
return p

// DA logon to non-DC
MATCH (c:Computer)-[:MemberOf]->(t:Group) 
WHERE NOT t.objectid ENDS WITH '-516'
WITH c as NonDC 
MATCH p=(NonDC)-[:HasSession]->(n:User)-[:MemberOf]-> (g:Group) 
WHERE g.name ENDS WITH '-512'
RETURN p

// old OS
MATCH (n:Computer) 
WHERE n.operatingsystem =~ '(?i).*\\b(2000|2003|2008|xp|vista|7|me)\\b.*' 
RETURN n



// Create User
MERGE (x:Base {objectid:'test-123'}) SET x:User, x.name='testuser123' RETURN x

// Owned Users to HighValue Groups
MATCH (u:User {owned:True})
MATCH (g:Group {highvalue:True})
MATCH p=shortestPath((u)-[*1..]->(g))

// Count of kerbies
MATCH (u:User) WHERE u.hasspn
RETURN COUNT(DISTINCT(u))

//Usr path to DA ALS/Default < count
MATCH p=shortestPath((u:User)-[:MemberOf|HasSession|AdminTo|AllExtendedRights|AddMember|ForceChangePassword|GenericAll|GenericWrite|Owns|WriteDacl|WriteOwner|ReadLAPSPassword|ReadGMSAPassword*1]->(g:Group {name:'DOMAIN ADMINS@COFFE.CUP'}))
WITH COUNT(p) AS pathcount
RETURN pathcount

// COunt Comp OS 2016
MATCH (x:Computer) WHERE x.operatingsystem CONTAINS '2016' RETURN COUNT(x)














