import React, { Component, Suspense, lazy } from 'react';
import { Route, Routes } from 'react-router-dom';

import Spinner from './shared/Spinner';

const Home = lazy(() => import('./pages/home'));
const ItemDetails = lazy(() => import('./pages/item-details'));

class AppRoutes extends Component {
  render () {
    return (
      <Suspense fallback={<Spinner/>}>
        <Routes>
          <Route path="" element={<Home />} />
          <Route path="/item-details" element={<ItemDetails />} />
        </Routes>
      </Suspense>
    );
  }
}

export default AppRoutes;