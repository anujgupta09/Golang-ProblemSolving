// 3. Write a program to input principal, time, and rate (P, T, R) from the user and find Simple Interest.

package main

import "fmt"

func main() {
	var P, R, T int
	fmt.Scan(&P, &R, &T)

	SI := (P * R * T) / 100

	fmt.Println(SI)
}
