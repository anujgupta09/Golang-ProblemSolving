// 3. [A person is eligible to vote if his/her age is greater than or equal to 18.
//  Define a method to find out if he/she is eligible to vote.]
// (https://www.efaculty.in/java-programs/voting-age-program-in-java/)

package main

import "fmt"

func main() {
	var age int
	fmt.Scan(&age)
	fmt.Println(eligible(age))
}
func eligible(age int) string {
	if age > 17 {
		return "Eligible"
	} else {
		return "Not Eligible"
	}
}
