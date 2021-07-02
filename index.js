import React, {Component} from "react";
import UIModal from "./UIModal";

export default class Root extends Component {
    render() {
        return (
            <UIModal {...this.props}/>
        );
    }
}