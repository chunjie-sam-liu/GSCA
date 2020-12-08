import { PdfModule } from './pdf.module';
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MaterialElevationDirective } from './directives/material-elevation.directive';
import { MaterialModule } from './material.module';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { EchartsModule } from './echarts.module';
import { HeaderComponent } from './components/header/header.component';
import { FooterComponent } from './components/footer/footer.component';
import { SidebarComponent } from './components/sidebar/sidebar.component';

@NgModule({
  declarations: [MaterialElevationDirective, HeaderComponent, FooterComponent, SidebarComponent],
  imports: [CommonModule, RouterModule, FormsModule, ReactiveFormsModule, MaterialModule, EchartsModule, PdfModule],
  exports: [
    MaterialElevationDirective,
    FormsModule,
    ReactiveFormsModule,
    MaterialModule,
    EchartsModule,
    PdfModule,
    HeaderComponent,
    FooterComponent,
    SidebarComponent,
  ],
})
export class SharedModule {}
