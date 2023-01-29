// 4. Calculate Discount Of Product

package main

import "fmt"

func main() {
	var priceOfProduct, discountedPrice int
	fmt.Scan(&priceOfProduct, &discountedPrice)

	discountOnProduct := priceOfProduct - discountedPrice
	fmt.Println(discountOnProduct)
}
