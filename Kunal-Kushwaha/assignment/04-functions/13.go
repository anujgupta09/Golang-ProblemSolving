/*
13. [Write a function that returns all prime numbers between two given numbers.]
(https://www.geeksforgeeks.org/program-to-find-prime-numbers-between-given-interval/)
*/

package main

import "fmt"

////////////////////////////////// main ///////////////////////////////

func main() {
	var num1, num2 int
	fmt.Scan(&num1, &num2)
	list := allPrime(num1, num2)
	fmt.Println(list)
}

//////////////////////////////////  prime  ////////////////////////////

func allPrime(num1, num2 int) []int {
	var list []int = []int{}
	for i := num1; i <= num2; i++ {
		if i <= 1 {
			continue
		}
		var primeOrNot = "Consider Not Prime"
		for j := 2; j < i; j++ {
			if i%j == 0 {
				primeOrNot = "prime"
			}
		}
		if primeOrNot != "prime" {
			list = append(list, i)
		}
	}
	return list
}

///////////////////////////////////////////////////////////////////////
