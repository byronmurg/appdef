import Logo from "../assets/images/WhiteLogo.png"

export default
function LogoComponent(props) {
	return <img alt="appdef.io" src={Logo} {...props} />
}
