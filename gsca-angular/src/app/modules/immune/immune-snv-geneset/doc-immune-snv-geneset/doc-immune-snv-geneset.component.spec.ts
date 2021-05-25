import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmuneSnvGenesetComponent } from './doc-immune-snv-geneset.component';

describe('DocImmuneSnvGenesetComponent', () => {
  let component: DocImmuneSnvGenesetComponent;
  let fixture: ComponentFixture<DocImmuneSnvGenesetComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmuneSnvGenesetComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmuneSnvGenesetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
