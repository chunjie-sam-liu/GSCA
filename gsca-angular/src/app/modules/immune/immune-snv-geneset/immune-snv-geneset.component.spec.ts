import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneSnvGenesetComponent } from './immune-snv-geneset.component';

describe('ImmuneSnvGenesetComponent', () => {
  let component: ImmuneSnvGenesetComponent;
  let fixture: ComponentFixture<ImmuneSnvGenesetComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneSnvGenesetComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneSnvGenesetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
