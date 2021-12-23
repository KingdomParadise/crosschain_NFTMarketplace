import React from "react";
import { Link } from "react-router-dom";

const ActivitySidebar = () => {
	return (
		<>
			<div className="side-bar-area pl-20">
				<div className="side-bar-widget">
					<h3 className="title">
						Filter
						<Link to="/activity">
							<a href={() => false}>Clear All</a>
						</Link>
					</h3>
					<form className="search-form">
						<input
							type="search"
							className="form-control"
							placeholder="Search keyword"
						/>
						<button type="submit">
							<i className="ri-search-line"></i>
						</button>
					</form>
				</div>

				<div className="side-bar-widget-categories">
					<h3 className="title">Categories</h3>
					<ul>
						<li>
							<Link to="/categories">
								<a href={() => false}>Art</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Virtual Worlds</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Collectibles</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Music</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Games</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Domains</a>
							</Link>
						</li>
						<li>
							<Link to="/categories">
								<a href={() => false}>Memes</a>
							</Link>
						</li>
					</ul>
				</div>
			</div>
		</>
	);
};

export default ActivitySidebar;
