$id = get-random

#region C# FastListCompare Class Definition
Add-Type -TypeDefinition @" 
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;

public class NSFastListCompare$id {
    public string[] list1 { get; set; }
    public string[] list2 { get; set; }

    // Represents a node in the Trie
    public class TrieNode
    {
        public ConcurrentDictionary<char, TrieNode> Children = new ConcurrentDictionary<char, TrieNode>();
        public bool EndOfWord;
    }

    // Implements the Trie data structure
    public class Trie
    {
        private TrieNode root;

        public Trie()
        {
            root = new TrieNode();
        }

        // Insert a word into the Trie
        public void Insert(string word)
        {
            TrieNode node = root;
            foreach (char c in word)
            {
                node = node.Children.GetOrAdd(c, new TrieNode());
            }
            node.EndOfWord = true;
        }

        // Insert all suffixes of the word into the Trie
        public void InsertAllSuffixes(string word)
        {
            for (int i = 0; i < word.Length; i++)
            {
                Insert(word.Substring(i));
            }
        }

        // Search if the Trie contains the given word as a substring
        public bool ContainsSubstring(string word)
        {
            TrieNode node = root;
            foreach (char c in word)
            {
                if (node.Children.TryGetValue(c, out TrieNode nextNode))
                {
                    node = nextNode;
                }
                else
                {
                    return false;
                }
            }
            return true;
        }
    }

    // Function for exact matching
    public List<string> InBothLists(bool caseSensitive)
    {
        HashSet<string> set1, set2;
        if (caseSensitive)
        {
            set1 = new HashSet<string>(list1);
            set2 = new HashSet<string>(list2);
        }
        else
        {
            set1 = new HashSet<string>(list1, StringComparer.OrdinalIgnoreCase);
            set2 = new HashSet<string>(list2, StringComparer.OrdinalIgnoreCase);
        }

        set1.IntersectWith(set2);  // Intersection of both sets
        return new List<string>(set1);
    }

    // Function to return elements from list1 but not in list2
    public List<string> InList1ButNotList2(bool caseSensitive)
    {
        HashSet<string> set1, set2;
        if (caseSensitive)
        {
            set1 = new HashSet<string>(list1);
            set2 = new HashSet<string>(list2);
        }
        else
        {
            set1 = new HashSet<string>(list1, StringComparer.OrdinalIgnoreCase);
            set2 = new HashSet<string>(list2, StringComparer.OrdinalIgnoreCase);
        }

        set1.ExceptWith(set2);  // Difference
        return new List<string>(set1);
    }

    // Function to return elements from list2 but not in list1
    public List<string> InList2ButNotList1(bool caseSensitive)
    {
        HashSet<string> set1, set2;
        if (caseSensitive)
        {
            set1 = new HashSet<string>(list1);
            set2 = new HashSet<string>(list2);
        }
        else
        {
            set1 = new HashSet<string>(list1, StringComparer.OrdinalIgnoreCase);
            set2 = new HashSet<string>(list2, StringComparer.OrdinalIgnoreCase);
        }

        set2.ExceptWith(set1);  // Difference
        return new List<string>(set2);
    }

    // Function to check if list2 substrings are in list1 using the optimized Trie approach
    public List<string> List1SubStringInList2(bool caseSensitive)
    {
        Trie trie = new Trie();

        // Insert all suffixes of all words in list2 into the Trie
        Parallel.ForEach(list2, item2 =>
        {
            string itemToInsert = caseSensitive ? item2 : item2.ToLower();
            trie.InsertAllSuffixes(itemToInsert);
        });

        List<string> matches = new List<string>();

        // Check if any word in list1 is a substring of any word in list2 using the Trie
        Parallel.ForEach(list1, item1 =>
        {
            string itemToCheck = caseSensitive ? item1 : item1.ToLower();
            if (trie.ContainsSubstring(itemToCheck))
            {
                lock (matches)
                {
                    matches.Add(item1);
                }
            }
        });

        return matches;
    }

    // Function to check if list1 substrings are in list2 using the optimized Trie approach
    public List<string> List2SubStringInList1(bool caseSensitive)
    {
        Trie trie = new Trie();

        // Insert all suffixes of all words in list1 into the Trie
        Parallel.ForEach(list1, item1 =>
        {
            string itemToInsert = caseSensitive ? item1 : item1.ToLower();
            trie.InsertAllSuffixes(itemToInsert);
        });

        List<string> matches = new List<string>();

        // Check if any word in list2 is a substring of any word in list1 using the Trie
        Parallel.ForEach(list2, item2 =>
        {
            string itemToCheck = caseSensitive ? item2 : item2.ToLower();
            if (trie.ContainsSubstring(itemToCheck))
            {
                lock (matches)
                {
                    matches.Add(item2);
                }
            }
        });

        return matches;
    }
}
"@
#endregion


<#
.SYNOPSIS
Finds elements present in both lists.

.DESCRIPTION
This function compares two lists and returns the elements that are present in both lists. It can perform case-sensitive or case-insensitive comparisons.

.PARAMETER list1
The first list to compare.

.PARAMETER list2
The second list to compare.

.PARAMETER caseSensitive
Boolean flag to indicate if the comparison should be case-sensitive.

.EXAMPLE
$commonItems = Compare-InBothLists -list1 $list1 -list2 $list2 -caseSensitive $false
#>
function Compare-InBothLists {
    param (
        [Parameter(Mandatory=$true)]
        [array]$list1,
        
        [Parameter(Mandatory=$true)]
        [array]$list2,

        [bool]$caseSensitive = $false
    )

    $Compare = New-Object NSFastListCompare$id
    $Compare.list1 = $list1
    $Compare.list2 = $list2
    $CompareReturn = @()
    $CompareReturn = $Compare.InBothLists($caseSensitive)
    
    return $CompareReturn
}

<#
.SYNOPSIS
Finds elements present in list1 but not in list2.

.DESCRIPTION
This function compares two lists and returns the elements that are present in list1 but not in list2. It can perform case-sensitive or case-insensitive comparisons.

.PARAMETER list1
The first list to compare.

.PARAMETER list2
The second list to compare.

.PARAMETER caseSensitive
Boolean flag to indicate if the comparison should be case-sensitive.

.EXAMPLE
$uniqueItems = Compare-InList1ButNotList2 -list1 $list1 -list2 $list2 -caseSensitive $false
#>
function Compare-InList1ButNotList2 {
    param (
        [Parameter(Mandatory=$true)]
        [array]$list1,
        
        [Parameter(Mandatory=$true)]
        [array]$list2,

        [bool]$caseSensitive = $false
    )

    $Compare = New-Object NSFastListCompare$id
    $Compare.list1 = $list1
    $Compare.list2 = $list2
    $CompareReturn = @()
    $CompareReturn = $Compare.InList1ButNotList2($caseSensitive)
    
    return $CompareReturn
}

<#
.SYNOPSIS
Finds elements present in list2 but not in list1.

.DESCRIPTION
This function compares two lists and returns the elements that are present in list2 but not in list1. It can perform case-sensitive or case-insensitive comparisons.

.PARAMETER list1
The first list to compare.

.PARAMETER list2
The second list to compare.

.PARAMETER caseSensitive
Boolean flag to indicate if the comparison should be case-sensitive.

.EXAMPLE
$uniqueItems = Compare-InList2ButNotList1 -list1 $list1 -list2 $list2 -caseSensitive $false
#>
function Compare-InList2ButNotList1 {
    param (
        [Parameter(Mandatory=$true)]
        [array]$list1,
        
        [Parameter(Mandatory=$true)]
        [array]$list2,

        [bool]$caseSensitive = $false
    )

    $Compare = New-Object NSFastListCompare$id
    $Compare.list1 = $list1
    $Compare.list2 = $list2
    $CompareReturn = @()
    $CompareReturn = $Compare.InList2ButNotList1($caseSensitive)
    
    return $CompareReturn
}

<#
.SYNOPSIS
Finds elements in list1 that are substrings of elements in list2.

.DESCRIPTION
This function compares two lists and returns the elements in list1 that are substrings of any element in list2. It uses a Trie data structure for optimized substring search and can perform case-sensitive or case-insensitive comparisons.

.PARAMETER list1
The first list to compare.

.PARAMETER list2
The second list to compare.

.PARAMETER caseSensitive
Boolean flag to indicate if the comparison should be case-sensitive.

.EXAMPLE
$substringMatches = Compare-List1SubStringInList2 -list1 $list1 -list2 $list2 -caseSensitive $false
#>
function Compare-List1SubStringInList2 {
    param (
        [Parameter(Mandatory=$true)]
        [array]$list1,
        
        [Parameter(Mandatory=$true)]
        [array]$list2,

        [bool]$caseSensitive = $false
    )

    $Compare = New-Object NSFastListCompare$id
    $Compare.list1 = $list1
    $Compare.list2 = $list2
    $CompareReturn = @()
    $CompareReturn = $Compare.List1SubStringInList2($caseSensitive)
    
    return $CompareReturn
}

<#
.SYNOPSIS
Finds elements in list2 that are substrings of elements in list1.

.DESCRIPTION
This function compares two lists and returns the elements in list2 that are substrings of any element in list1. It uses a Trie data structure for optimized substring search and can perform case-sensitive or case-insensitive comparisons.

.PARAMETER list1
The first list to compare.

.PARAMETER list2
The second list to compare.

.PARAMETER caseSensitive
Boolean flag to indicate if the comparison should be case-sensitive.

.EXAMPLE
$substringMatches = Compare-List2SubStringInList1 -list1 $list1 -list2 $list2 -caseSensitive $false
#>
function Compare-List2SubStringInList1 {
    param (
        [Parameter(Mandatory=$true)]
        [array]$list1,
        
        [Parameter(Mandatory=$true)]
        [array]$list2,

        [bool]$caseSensitive = $false
    )

    $Compare = New-Object NSFastListCompare$id
    $Compare.list1 = $list1
    $Compare.list2 = $list2
    $CompareReturn = @()
    $CompareReturn = $Compare.List2SubStringInList1($caseSensitive)
    
    return $CompareReturn
}
