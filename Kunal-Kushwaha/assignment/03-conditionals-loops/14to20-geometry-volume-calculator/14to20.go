// 14. Volume Of Cone Java Program
// 15. Volume Of Prism
// 16. Volume Of Cylinder
// 17. Volume Of Sphere
// 18. Volume Of Pyramid
// 19. Curved Surface Area Of Cylinder
// 20. Total Surface Area Of Cube
package main

import "fmt"

func main() {
	// vol of pyramid
	var len, width, height float32
	fmt.Scan(&len, &width, &height)
	Vol := (len * width * height) / 2
	fmt.Println(Vol)
}
