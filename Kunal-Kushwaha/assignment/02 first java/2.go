// 2. Take name as input and print a greeting message for that particular name.

package main

import "fmt"

func main() {
	var name string
	fmt.Scan(&name)
	fmt.Printf("Welcome %s", name)

}
