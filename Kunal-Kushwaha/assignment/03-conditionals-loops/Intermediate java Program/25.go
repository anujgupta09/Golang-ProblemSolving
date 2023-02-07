// 25. Kunal is allowed to go out with his friends only on
// the even days of a given month. Write a program to count
// the number of days he can go out in the month of August.

package main

import "fmt"

func main() {
	var dayInAug = 31
	var count = 0
	for i := 1; i <= dayInAug; i++ {
		if i%2 == 0 {
			count += 1
		}
	}
	fmt.Println(count)
}
