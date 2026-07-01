/*
11. [Count Items Matching a Rule]
(https://leetcode.com/problems/count-items-matching-a-rule/)
*/

package main

import "fmt"

func main() {
	arr := [][]string{
		{"phone", "blue", "pixel"},
		{"computer", "silver", "lenovo"},
		{"phone", "silver", "iphone"},
	}
	ruleKey := "color"
	ruleValue := "silver"
	fmt.Println(countMatches(arr, ruleKey, ruleValue))
}

/////////////// countMatches //////////////////////////
func countMatches(items [][]string, ruleKey string, ruleValue string) int {
	var myMap = map[string]int{
		"type":  0,
		"color": 1,
		"name":  2,
	}
	// var myMap = make(map[string]int)
	// myMap["type"] = 0
	// myMap["color"] = 1
	// myMap["name"] = 2

	match := 0
	for i := 0; i < len(items); i++ {
		if items[i][myMap[ruleKey]] == ruleValue {
			match++
		}
	}
	return match
}

// func countMatches(items [][]string, ruleKey string, ruleValue string) int {

// 	var pos int
// 	if ruleKey == "type" {
// 		pos = 0
// 	}
// 	if ruleKey == "color" {
// 		pos = 1
// 	}
// 	if ruleKey == "name" {
// 		pos = 2
// 	}
// 	match := 0
// 	for i := 0; i < len(items); i++ {
// 		fmt.Println("i :", i)
// 		if items[i][pos] == ruleValue {
// 			fmt.Println(items[i][pos], ruleValue)
// 			match += 1
// 		}
// 		fmt.Println(" \n ")
// 	}
// 	return match
// }
