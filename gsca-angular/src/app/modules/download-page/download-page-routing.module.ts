import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DownloadPageComponent } from './download-page.component';

const routes: Routes = [
  {
    path: '',
    component: DownloadPageComponent,
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class DownloadPageRoutingModule {}
